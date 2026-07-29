"""
PatchingDispatcher Lambda

Single function handling all 7 jobs in the patching pipeline, dispatched
by event["task"]:

  compliance_check     - pulls patch compliance state for tagged instances
  patch_instance        - sends AWS-RunPatchBaseline Install to one instance
  classify_failure       - quick diagnostic + transient/permission/real classification
  rca_collector          - full OS-level diagnostic document + S3 archive
  pre_backup_snapshot   - on-demand AWS Backup job before patching
  backup_restore          - restore approval notification (SNS) + actual restore
  report_builder          - compiles a CSV report and sends it as an email attachment via SES

NOTE: merging these into one function means one IAM role covers the union
of all permissions needed across every task, and CloudWatch metrics/alarms
can no longer distinguish "classify_failure is erroring" from "report_builder
is erroring" - both show up as errors on the same function. Keep that
trade-off in mind if you split this back out later.
"""

import os
import time
import json
import csv
import io
from datetime import datetime, timezone
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.application import MIMEApplication

import boto3

ssm = boto3.client("ssm")
ec2 = boto3.client("ec2")
s3 = boto3.client("s3")
ses = boto3.client("ses")
sns = boto3.client("sns")
backup = boto3.client("backup")

ENVIRONMENT_TAG_VALUE = os.environ.get("ENVIRONMENT_TAG_VALUE", "nprod")
RCA_DOCUMENT_NAME = os.environ.get("RCA_DOCUMENT_NAME", "")
REPORT_BUCKET = os.environ.get("REPORT_BUCKET", "")
BACKUP_VAULT_NAME = os.environ.get("BACKUP_VAULT_NAME", "")
BACKUP_IAM_ROLE_ARN = os.environ.get("BACKUP_IAM_ROLE_ARN", "")
APPROVAL_TOPIC_ARN = os.environ.get("APPROVAL_TOPIC_ARN", "")
SENDER_EMAIL = os.environ.get("SENDER_EMAIL", "")
RECIPIENT_EMAILS = os.environ.get("RECIPIENT_EMAILS", "").split(",") if os.environ.get("RECIPIENT_EMAILS") else []


# ---------------------------------------------------------------------------
# 1) compliance_check
# ---------------------------------------------------------------------------
def get_tagged_instance_ids():
    """Return {instance_id: name_tag_value} for every instance tagged
    environment=<ENVIRONMENT_TAG_VALUE>. name_tag_value is '' if no Name tag."""
    instance_names = {}
    paginator = ec2.get_paginator("describe_instances")
    for page in paginator.paginate(
        Filters=[
            {"Name": "tag:environment", "Values": [ENVIRONMENT_TAG_VALUE]},
            {"Name": "instance-state-name", "Values": ["running"]},
        ]
    ):
        for reservation in page["Reservations"]:
            for instance in reservation["Instances"]:
                instance_id = instance["InstanceId"]
                name_tag = ""
                for tag in instance.get("Tags", []):
                    if tag["Key"] == "Name":
                        name_tag = tag["Value"]
                        break
                instance_names[instance_id] = name_tag
    return instance_names


def get_patch_states(instance_ids):
    results = []
    for i in range(0, len(instance_ids), 50):
        batch = instance_ids[i : i + 50]
        response = ssm.describe_instance_patch_states(InstanceIds=batch)
        results.extend(response.get("InstancePatchStates", []))
    return results


def task_compliance_check(event, context):
    instance_names = get_tagged_instance_ids()
    instance_ids = list(instance_names.keys())

    if not instance_ids:
        return {
            "instanceCount": 0,
            "compliant": [],
            "nonCompliant": [],
            "environmentTag": ENVIRONMENT_TAG_VALUE,
        }

    patch_states = get_patch_states(instance_ids)
    compliant, non_compliant = [], []

    for state in patch_states:
        instance_id = state["InstanceId"]
        record = {
            "instanceId": instance_id,
            "instanceName": instance_names.get(instance_id, ""),
            "installedCount": state.get("InstalledCount", 0),
            "missingCount": state.get("MissingCount", 0),
            "failedCount": state.get("FailedCount", 0),
            "operation": state.get("Operation", "Unknown"),
            "lastScanTime": str(state.get("OperationEndTime", "")),
        }
        if record["missingCount"] == 0 and record["failedCount"] == 0:
            compliant.append(record)
        else:
            non_compliant.append(record)

    return {
        "instanceCount": len(instance_ids),
        "compliant": compliant,
        "nonCompliant": non_compliant,
        "environmentTag": ENVIRONMENT_TAG_VALUE,
    }


# ---------------------------------------------------------------------------
# 2) patch_instance_start / patch_instance_check
#
# Split into two tasks instead of one polling loop, because Windows patch +
# reboot can easily take longer than AWS Lambda's hard 900-second (15 min)
# maximum timeout. Polling inside a single Lambda invocation risks the
# function being killed mid-patch on any reboot-heavy run. Instead:
#   - patch_instance_start sends the command and returns immediately
#   - patch_instance_check does ONE status check and returns
#   - Step Functions itself loops (Wait -> check -> Choice) with no time cap
# ---------------------------------------------------------------------------
def task_patch_instance_start(event, context):
    instance_id = event["instanceId"]
    reboot_option = os.environ.get("REBOOT_OPTION", "RebootIfNeeded")

    command = ssm.send_command(
        InstanceIds=[instance_id],
        DocumentName="AWS-RunPatchBaseline",
        Parameters={"Operation": ["Install"], "RebootOption": [reboot_option]},
        TimeoutSeconds=1800,  # SSM-side command timeout - generous for patch+reboot
    )
    return {"instanceId": instance_id, "commandId": command["Command"]["CommandId"]}


def task_patch_instance_check(event, context):
    instance_id = event["instanceId"]
    command_id = event["commandId"]

    try:
        result = ssm.get_command_invocation(CommandId=command_id, InstanceId=instance_id)
        status = result["Status"]
    except ssm.exceptions.InvocationDoesNotExist:
        # command not registered on the instance yet (e.g. mid-reboot) - treat as still in progress
        status = "InProgress"
        result = {}

    return {
        "instanceId": instance_id,
        "commandId": command_id,
        "executionStatus": status,
        "isComplete": status in ("Success", "Failed", "Cancelled", "TimedOut"),
        "output": result.get("StandardOutputContent", "")[:2000],
        "error": result.get("StandardErrorContent", "")[:2000],
    }


# ---------------------------------------------------------------------------
# 3) classify_failure
# ---------------------------------------------------------------------------
QUICK_CHECK_COMMANDS = [
    "(Get-PSDrive C).Free / 1GB",
    "Get-Service wuauserv | Select-Object -ExpandProperty Status",
    "Test-Connection -ComputerName download.windowsupdate.com -Count 1 -Quiet",
]

PERMISSION_ERROR_MARKERS = ["AccessDenied", "is not authorized to perform", "UnauthorizedOperation"]
TRANSIENT_MARKERS = [
    "Could not resolve host",
    "The remote name could not be resolved",
    "A connection attempt failed",
    "timed out",
]


def run_quick_diagnostic(instance_id):
    command = ssm.send_command(
        InstanceIds=[instance_id],
        DocumentName="AWS-RunPowerShellScript",
        Parameters={"commands": QUICK_CHECK_COMMANDS},
        TimeoutSeconds=60,
    )
    command_id = command["Command"]["CommandId"]

    for _ in range(15):
        time.sleep(4)
        try:
            result = ssm.get_command_invocation(CommandId=command_id, InstanceId=instance_id)
            if result["Status"] in ("Success", "Failed", "Cancelled", "TimedOut"):
                return result
        except ssm.exceptions.InvocationDoesNotExist:
            continue
    return {"Status": "TimedOut", "StandardOutputContent": "", "StandardErrorContent": ""}


def classify(output_text, error_text, top_level_error):
    combined = f"{output_text}\n{error_text}\n{top_level_error}"
    for marker in PERMISSION_ERROR_MARKERS:
        if marker in combined:
            return "permission_denied"
    for marker in TRANSIENT_MARKERS:
        if marker in combined:
            return "transient"
    return "real_failure"


def task_classify_failure(event, context):
    instance_id = event["instanceId"]
    top_level_error = event.get("error", "")

    diagnostic_result = run_quick_diagnostic(instance_id)
    output_text = diagnostic_result.get("StandardOutputContent", "")
    error_text = diagnostic_result.get("StandardErrorContent", "")

    return {
        "instanceId": instance_id,
        "classification": classify(output_text, error_text, top_level_error),
        "diagnosticOutput": output_text,
        "diagnosticError": error_text,
    }


# ---------------------------------------------------------------------------
# 4) rca_collector
# ---------------------------------------------------------------------------
def run_rca_document(instance_id):
    command = ssm.send_command(
        InstanceIds=[instance_id],
        DocumentName=RCA_DOCUMENT_NAME,
        TimeoutSeconds=180,
    )
    command_id = command["Command"]["CommandId"]

    for _ in range(30):
        time.sleep(5)
        try:
            result = ssm.get_command_invocation(CommandId=command_id, InstanceId=instance_id)
            if result["Status"] in ("Success", "Failed", "Cancelled", "TimedOut"):
                return result
        except ssm.exceptions.InvocationDoesNotExist:
            continue

    return {
        "Status": "TimedOut",
        "StandardOutputContent": "RCA collection timed out waiting for instance response.",
        "StandardErrorContent": "",
    }


def archive_rca_to_s3(instance_id, execution_id, output_text):
    timestamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    key = f"rca-reports/{execution_id}/{instance_id}/{timestamp}.log"
    s3.put_object(Bucket=REPORT_BUCKET, Key=key, Body=output_text.encode("utf-8"), ContentType="text/plain")
    return f"s3://{REPORT_BUCKET}/{key}"


def extract_rca_summary(output_text):
    summary_lines = []
    for section in output_text.split("--- "):
        if not section.strip():
            continue
        header, _, body = section.partition("---")
        first_line = body.strip().split("\n")[0] if body.strip() else "no data"
        summary_lines.append(f"{header.strip()}: {first_line}")
    return " | ".join(summary_lines[:6])


def task_rca_collector(event, context):
    instance_id = event["instanceId"]
    execution_id = event.get("executionId", context.aws_request_id)

    result = run_rca_document(instance_id)
    output_text = result.get("StandardOutputContent", "")
    error_text = result.get("StandardErrorContent", "")
    full_output = output_text + ("\n\nERRORS:\n" + error_text if error_text else "")

    s3_path = archive_rca_to_s3(instance_id, execution_id, full_output)

    return {
        "instanceId": instance_id,
        "rcaStatus": result["Status"],
        "rcaSummary": extract_rca_summary(output_text),
        "rcaFullLogPath": s3_path,
    }


# ---------------------------------------------------------------------------
# 5) pre_backup_snapshot
# ---------------------------------------------------------------------------
def get_instance_arn(instance_id):
    region = boto3.session.Session().region_name
    account_id = boto3.client("sts").get_caller_identity()["Account"]
    return f"arn:aws:ec2:{region}:{account_id}:instance/{instance_id}"


def task_pre_backup_snapshot(event, context):
    instance_id = event["instanceId"]
    execution_id = event.get("executionId", context.aws_request_id)

    resource_arn = get_instance_arn(instance_id)

    response = backup.start_backup_job(
        BackupVaultName=BACKUP_VAULT_NAME,
        ResourceArn=resource_arn,
        IamRoleArn=BACKUP_IAM_ROLE_ARN,
        IdempotencyToken=f"{execution_id}-{instance_id}",
        RecoveryPointTags={"PatchExecutionId": execution_id, "TriggerType": "pre-patch-on-demand"},
    )
    backup_job_id = response["BackupJobId"]

    for _ in range(60):
        time.sleep(10)
        job = backup.describe_backup_job(BackupJobId=backup_job_id)
        state = job["State"]
        if state in ("COMPLETED", "FAILED", "ABORTED", "EXPIRED"):
            return {
                "instanceId": instance_id,
                "backupJobId": backup_job_id,
                "backupState": state,
                "recoveryPointArn": job.get("RecoveryPointArn", ""),
            }

    return {"instanceId": instance_id, "backupJobId": backup_job_id, "backupState": "TIMED_OUT_WAITING", "recoveryPointArn": ""}


# ---------------------------------------------------------------------------
# 6) backup_restore (request_approval / restore actions, nested under this task)
# ---------------------------------------------------------------------------
def task_backup_restore(event, context):
    sub_action = event.get("subAction")

    if sub_action == "request_approval":
        instance_id = event["instanceId"]
        task_token = event["taskToken"]
        rca_summary = event.get("rcaSummary", "no RCA summary available")

        message = {
            "instanceId": instance_id,
            "rcaSummary": rca_summary,
            "taskToken": task_token,
            "approveCommand": (
                "aws stepfunctions send-task-success --task-token "
                f"'{task_token}' --task-output '{{\"approved\": true}}'"
            ),
            "rejectCommand": (
                "aws stepfunctions send-task-failure --task-token "
                f"'{task_token}' --error 'RestoreRejected' --cause 'Manually rejected by on-call'"
            ),
        }
        sns.publish(
            TopicArn=APPROVAL_TOPIC_ARN,
            Subject=f"Restore approval needed: {instance_id}",
            Message=json.dumps(message, indent=2),
        )
        return {"status": "approval_requested", "instanceId": instance_id}

    elif sub_action == "restore":
        instance_id = event["instanceId"]
        recovery_point_arn = event["recoveryPointArn"]
        response = backup.start_restore_job(
            RecoveryPointArn=recovery_point_arn,
            IamRoleArn=BACKUP_IAM_ROLE_ARN,
            ResourceType="EC2",
        )
        return {"instanceId": instance_id, "restoreJobId": response["RestoreJobId"], "restoreTriggered": True}

    else:
        raise ValueError(f"Unknown subAction: {sub_action}")


# ---------------------------------------------------------------------------
# 7) report_builder - CSV report (instance name, all fields, sent as an
# email attachment rather than inline HTML)
# ---------------------------------------------------------------------------
CSV_FIELDNAMES = [
    "instanceId",
    "instanceName",
    "installedCount",
    "missingCount",
    "failedCount",
    "operation",
    "lastScanTime",
    "complianceStatus",       # Compliant / NonCompliant
    "executionStatus",        # Install-mode only
    "rcaSummary",
    "backupTaken",
    "restoreTriggered",
    "environmentTag",
    "reportOperationMode",    # Scan / Install - the run's overall mode
    "executionId",
    "reportGeneratedAt",      # execution time this report was built
]


def build_csv_report(event):
    operation = event.get("operation", "Scan")
    environment_tag = event.get("environmentTag", "nprod")
    compliant = event.get("compliant", [])
    non_compliant = event.get("nonCompliant", [])
    execution_id = event.get("executionId", "")
    generated_at = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")

    buffer = io.StringIO()
    writer = csv.DictWriter(buffer, fieldnames=CSV_FIELDNAMES)
    writer.writeheader()

    def write_rows(records, compliance_status):
        for r in records:
            writer.writerow({
                "instanceId": r.get("instanceId", ""),
                "instanceName": r.get("instanceName", ""),
                "installedCount": r.get("installedCount", ""),
                "missingCount": r.get("missingCount", ""),
                "failedCount": r.get("failedCount", ""),
                "operation": r.get("operation", ""),
                "lastScanTime": r.get("lastScanTime", ""),
                "complianceStatus": compliance_status,
                "executionStatus": r.get("executionStatus", ""),
                "rcaSummary": r.get("rcaSummary", ""),
                "backupTaken": r.get("backupTaken", ""),
                "restoreTriggered": r.get("restoreTriggered", ""),
                "environmentTag": environment_tag,
                "reportOperationMode": operation,
                "executionId": execution_id,
                "reportGeneratedAt": generated_at,
            })

    write_rows(compliant, "Compliant")
    write_rows(non_compliant, "NonCompliant")

    return buffer.getvalue()


def send_csv_email(csv_content, operation, execution_id):
    subject = f"nprod patching report - {operation} - {datetime.now(timezone.utc).strftime('%Y-%m-%d')}"
    filename = f"nprod-patching-report-{execution_id}.csv"

    msg = MIMEMultipart()
    msg["Subject"] = subject
    msg["From"] = SENDER_EMAIL
    msg["To"] = ", ".join(RECIPIENT_EMAILS)

    body_text = (
        f"nprod patching report attached.\n\n"
        f"Operation: {operation}\n"
        f"Execution ID: {execution_id}\n"
        f"Generated: {datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M:%S UTC')}\n"
    )
    msg.attach(MIMEText(body_text, "plain"))

    attachment = MIMEApplication(csv_content.encode("utf-8"))
    attachment.add_header("Content-Disposition", "attachment", filename=filename)
    msg.attach(attachment)

    ses.send_raw_email(
        Source=SENDER_EMAIL,
        Destinations=RECIPIENT_EMAILS,
        RawMessage={"Data": msg.as_string()},
    )


def task_report_builder(event, context):
    execution_id = event.get("executionId", context.aws_request_id)
    operation = event.get("operation", "Scan")

    csv_content = build_csv_report(event)

    timestamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    key = f"csv-reports/{execution_id}/{timestamp}.csv"
    s3.put_object(Bucket=REPORT_BUCKET, Key=key, Body=csv_content.encode("utf-8"), ContentType="text/csv")

    send_csv_email(csv_content, operation, execution_id)

    return {"statusCode": 200, "reportArchivePath": f"s3://{REPORT_BUCKET}/{key}", "recipientCount": len(RECIPIENT_EMAILS)}


# ---------------------------------------------------------------------------
# Dispatcher
# ---------------------------------------------------------------------------
TASK_MAP = {
    "compliance_check": task_compliance_check,
    "patch_instance_start": task_patch_instance_start,
    "patch_instance_check": task_patch_instance_check,
    "classify_failure": task_classify_failure,
    "rca_collector": task_rca_collector,
    "pre_backup_snapshot": task_pre_backup_snapshot,
    "backup_restore": task_backup_restore,
    "report_builder": task_report_builder,
}


def lambda_handler(event, context):
    task = event.get("task")
    if task not in TASK_MAP:
        raise ValueError(f"Unknown or missing 'task' in event: {task!r}. Valid tasks: {list(TASK_MAP.keys())}")
    return TASK_MAP[task](event, context)

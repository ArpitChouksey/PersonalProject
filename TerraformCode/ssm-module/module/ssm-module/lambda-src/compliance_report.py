"""
Compliance / non-compliance report generator.

Pulls Patch and Association compliance data from SSM for all managed
instances, builds a CSV, and writes it to S3 under Reports/.

RCA note (be honest with the reader of this file): this only surfaces the
failure detail AWS's own compliance API already recorded for a non-compliant
item (e.g. "FailedInstall", "MissingUpdate", a timeout reason). It is not a
deep root-cause investigation - Lambda has no way to log into an instance and
diagnose *why* (disk full, agent stuck, etc). Treat the RCA column as "what
AWS told us", not a full diagnosis.
"""
import boto3
import csv
import io
import os
from datetime import datetime, timezone

ssm = boto3.client("ssm")
ec2 = boto3.client("ec2")
s3 = boto3.client("s3")

BUCKET = os.environ["REPORTS_BUCKET"]
PREFIX = os.environ.get("REPORTS_PREFIX", "Reports/")

CSV_HEADERS = [
    "Date",
    "Time",
    "InstanceName",
    "InstanceId",
    "ComplianceType",
    "PatchKB",
    "Version",
    "Severity",
    "Status",
    "RCA",
]


def _instance_names(instance_ids):
    """Best-effort Name tag lookup. Returns {} entries as '' if not found."""
    names = {}
    if not instance_ids:
        return names
    try:
        paginator = ec2.get_paginator("describe_instances")
        for page in paginator.paginate(InstanceIds=list(instance_ids)):
            for reservation in page.get("Reservations", []):
                for inst in reservation.get("Instances", []):
                    iid = inst["InstanceId"]
                    name = ""
                    for tag in inst.get("Tags", []):
                        if tag["Key"] == "Name":
                            name = tag["Value"]
                            break
                    names[iid] = name
    except Exception as e:
        print(f"WARN: could not resolve instance names: {e}")
    return names


def _status_label(status):
    if status in ("COMPLIANT",):
        return "Success"
    if status in ("NON_COMPLIANT",):
        return "Failure"
    return status or "Unknown"


def _rca(details):
    """Pull whatever failure context AWS gave us out of a compliance item's
    Details map. Different compliance types populate different keys."""
    if not details:
        return ""
    for key in ("Title", "DocumentName", "Note", "Message"):
        if details.get(key):
            return str(details[key])
    return ""


def _collect_compliance_items(compliance_type):
    items = []
    paginator = ssm.get_paginator("list_compliance_items")
    for page in paginator.paginate(
        ResourceTypes=["ManagedInstance"],
        Filters=[{"Key": "ComplianceType", "Values": [compliance_type]}],
    ):
        items.extend(page.get("ComplianceItems", []))
    return items


def handler(event, context):
    now = datetime.now(timezone.utc)
    date_str = now.strftime("%Y-%m-%d")
    time_str = now.strftime("%H:%M:%S")

    all_items = []
    for compliance_type in ("Patch", "Association"):
        try:
            all_items.extend(
                (compliance_type, item) for item in _collect_compliance_items(compliance_type)
            )
        except Exception as e:
            print(f"WARN: failed to list {compliance_type} compliance items: {e}")

    instance_ids = {item.get("ResourceId") for _, item in all_items if item.get("ResourceId")}
    names = _instance_names(instance_ids)

    rows = []
    for compliance_type, item in all_items:
        instance_id = item.get("ResourceId", "")
        details = item.get("Details", {}) or {}
        status = item.get("Status", "")
        rows.append(
            {
                "Date": date_str,
                "Time": time_str,
                "InstanceName": names.get(instance_id, ""),
                "InstanceId": instance_id,
                "ComplianceType": compliance_type,
                "PatchKB": details.get("PatchKB") or details.get("Id") or (item.get("Id") if compliance_type == "Patch" else ""),
                "Version": details.get("InstalledVersion") or details.get("Version") or "",
                "Severity": item.get("Severity", ""),
                "Status": _status_label(status),
                "RCA": _rca(details) if status == "NON_COMPLIANT" else "",
            }
        )

    if not rows:
        print("No compliance items found - writing an empty report with headers only.")

    buf = io.StringIO()
    writer = csv.DictWriter(buf, fieldnames=CSV_HEADERS)
    writer.writeheader()
    for row in rows:
        writer.writerow(row)

    key = f"{PREFIX}compliance-report-{now.strftime('%Y%m%dT%H%M%SZ')}.csv"
    s3.put_object(
        Bucket=BUCKET,
        Key=key,
        Body=buf.getvalue().encode("utf-8"),
        ContentType="text/csv",
    )

    print(f"Wrote {len(rows)} rows to s3://{BUCKET}/{key}")
    return {
        "bucket": BUCKET,
        "key": key,
        "row_count": len(rows),
        "non_compliant_count": sum(1 for r in rows if r["Status"] == "Failure"),
    }

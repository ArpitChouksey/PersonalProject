{
  "Comment": "nprod patching pipeline - single dispatcher lambda, dispatched via 'task' field",
  "StartAt": "LoadOperationParameter",
  "States": {
    "LoadOperationParameter": {
      "Type": "Task",
      "Resource": "arn:aws:states:::aws-sdk:ssm:getParameter",
      "Parameters": {
        "Name": "${operation_mode_parameter_name}"
      },
      "ResultPath": "$.operationParam",
      "Next": "LoadTakeBackupParameter"
    },
    "LoadTakeBackupParameter": {
      "Type": "Task",
      "Resource": "arn:aws:states:::aws-sdk:ssm:getParameter",
      "Parameters": {
        "Name": "${take_backup_parameter_name}"
      },
      "ResultPath": "$.takeBackupParam",
      "Next": "NormalizeControlFlags"
    },
    "NormalizeControlFlags": {
      "Type": "Pass",
      "Parameters": {
        "operation.$": "$.operationParam.Parameter.Value",
        "takeBackup.$": "$.takeBackupParam.Parameter.Value"
      },
      "Next": "ComplianceCheck"
    },
    "ComplianceCheck": {
      "Type": "Task",
      "Resource": "${dispatcher_arn}",
      "Parameters": {
        "task": "compliance_check"
      },
      "ResultPath": "$.complianceResult",
      "Next": "MergeComplianceResult"
    },
    "MergeComplianceResult": {
      "Type": "Pass",
      "Parameters": {
        "operation.$": "$.operation",
        "takeBackup.$": "$.takeBackup",
        "environmentTag.$": "$.complianceResult.environmentTag",
        "compliant.$": "$.complianceResult.compliant",
        "nonCompliant.$": "$.complianceResult.nonCompliant",
        "executionId.$": "$$.Execution.Name"
      },
      "Next": "OperationChoice"
    },
    "OperationChoice": {
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.operation",
          "StringEquals": "Scan",
          "Next": "BuildScanReport"
        }
      ],
      "Default": "ProcessNonCompliantInstances"
    },
    "BuildScanReport": {
      "Type": "Task",
      "Resource": "${dispatcher_arn}",
      "Parameters": {
        "task": "report_builder",
        "operation.$": "$.operation",
        "environmentTag.$": "$.environmentTag",
        "compliant.$": "$.compliant",
        "nonCompliant.$": "$.nonCompliant",
        "executionId.$": "$.executionId"
      },
      "End": true
    },
    "ProcessNonCompliantInstances": {
      "Type": "Map",
      "ItemsPath": "$.nonCompliant",
      "MaxConcurrency": ${map_max_concurrency},
      "ResultPath": "$.processedInstances",
      "Parameters": {
        "instanceId.$": "$$.Map.Item.Value.instanceId",
        "takeBackup.$": "$.takeBackup",
        "executionId.$": "$.executionId",
        "retryCount": 0
      },
      "Iterator": {
        "StartAt": "TakeBackupChoice",
        "States": {
          "TakeBackupChoice": {
            "Type": "Choice",
            "Choices": [
              { "Variable": "$.takeBackup", "StringEquals": "true", "Next": "PreBackupSnapshot" }
            ],
            "Default": "PatchAttempt"
          },
          "PreBackupSnapshot": {
            "Type": "Task",
            "Resource": "${dispatcher_arn}",
            "Parameters": {
              "task": "pre_backup_snapshot",
              "instanceId.$": "$.instanceId",
              "executionId.$": "$.executionId"
            },
            "ResultPath": "$.backupResult",
            "Next": "PatchAttempt"
          },
          "PatchAttempt": {
            "Type": "Task",
            "Resource": "${dispatcher_arn}",
            "Parameters": {
              "task": "patch_instance_start",
              "instanceId.$": "$.instanceId"
            },
            "ResultPath": "$.patchStart",
            "Retry": [
              {
                "ErrorEquals": ["Lambda.ServiceException", "Lambda.AWSLambdaException", "Lambda.SdkClientException", "States.Timeout"],
                "IntervalSeconds": 60,
                "MaxAttempts": 3,
                "BackoffRate": 2.0
              }
            ],
            "Catch": [
              {
                "ErrorEquals": ["States.ALL"],
                "ResultPath": "$.patchError",
                "Next": "ClassifyFailure"
              }
            ],
            "Next": "WaitForPatchCommand"
          },
          "WaitForPatchCommand": {
            "Type": "Wait",
            "Seconds": 30,
            "Next": "CheckPatchStatus"
          },
          "CheckPatchStatus": {
            "Type": "Task",
            "Resource": "${dispatcher_arn}",
            "Parameters": {
              "task": "patch_instance_check",
              "instanceId.$": "$.instanceId",
              "commandId.$": "$.patchStart.commandId"
            },
            "ResultPath": "$.patchResult",
            "Next": "PatchCompleteChoice"
          },
          "PatchCompleteChoice": {
            "Type": "Choice",
            "Choices": [
              { "Variable": "$.patchResult.isComplete", "BooleanEquals": true, "Next": "PatchSuccessCheck" }
            ],
            "Default": "WaitForPatchCommand"
          },
          "PatchSuccessCheck": {
            "Type": "Choice",
            "Choices": [
              { "Variable": "$.patchResult.executionStatus", "StringEquals": "Success", "Next": "InstanceSucceeded" }
            ],
            "Default": "ClassifyFailure"
          },
          "ClassifyFailure": {
            "Type": "Task",
            "Resource": "${dispatcher_arn}",
            "Parameters": {
              "task": "classify_failure",
              "instanceId.$": "$.instanceId"
            },
            "ResultPath": "$.classifyResult",
            "Next": "ClassificationChoice"
          },
          "ClassificationChoice": {
            "Type": "Choice",
            "Choices": [
              { "Variable": "$.classifyResult.classification", "StringEquals": "permission_denied", "Next": "InstanceBlocked" },
              { "And": [
                  { "Variable": "$.classifyResult.classification", "StringEquals": "transient" },
                  { "Variable": "$.retryCount", "NumericLessThan": ${transient_retry_max_attempts} }
                ],
                "Next": "IncrementRetryAndRetry" }
            ],
            "Default": "RCACollector"
          },
          "IncrementRetryAndRetry": {
            "Type": "Pass",
            "Parameters": {
              "instanceId.$": "$.instanceId",
              "takeBackup.$": "$.takeBackup",
              "executionId.$": "$.executionId",
              "backupResult.$": "$.backupResult",
              "retryCount.$": "States.MathAdd($.retryCount, 1)"
            },
            "Next": "PatchAttempt"
          },
          "RCACollector": {
            "Type": "Task",
            "Resource": "${dispatcher_arn}",
            "Parameters": {
              "task": "rca_collector",
              "instanceId.$": "$.instanceId",
              "executionId.$": "$.executionId"
            },
            "ResultPath": "$.rcaResult",
            "Next": "PostRCARestoreChoice"
          },
          "PostRCARestoreChoice": {
            "Type": "Choice",
            "Choices": [
              { "Variable": "$.takeBackup", "StringEquals": "true", "Next": "RequestRestoreApproval" }
            ],
            "Default": "InstanceFailedNoBackup"
          },
          "RequestRestoreApproval": {
            "Type": "Task",
            "Resource": "arn:aws:states:::lambda:invoke.waitForTaskToken",
            "TimeoutSeconds": 21600,
            "Parameters": {
              "FunctionName": "${dispatcher_arn}",
              "Payload": {
                "task": "backup_restore",
                "subAction": "request_approval",
                "instanceId.$": "$.instanceId",
                "rcaSummary.$": "$.rcaResult.rcaSummary",
                "taskToken.$": "$$.Task.Token"
              }
            },
            "ResultPath": "$.approvalResult",
            "Catch": [
              {
                "ErrorEquals": ["States.Timeout"],
                "Next": "InstanceFailedApprovalTimeout"
              },
              {
                "ErrorEquals": ["States.ALL"],
                "Next": "InstanceFailedRestoreRejected"
              }
            ],
            "Next": "ExecuteRestore"
          },
          "ExecuteRestore": {
            "Type": "Task",
            "Resource": "${dispatcher_arn}",
            "Parameters": {
              "task": "backup_restore",
              "subAction": "restore",
              "instanceId.$": "$.instanceId",
              "recoveryPointArn.$": "$.backupResult.recoveryPointArn"
            },
            "ResultPath": "$.restoreResult",
            "Next": "InstanceRestored"
          },
          "InstanceSucceeded": {
            "Type": "Pass",
            "Parameters": {
              "instanceId.$": "$.instanceId",
              "executionStatus": "Success",
              "rcaSummary": "-",
              "backupTaken.$": "$.takeBackup",
              "restoreTriggered": false
            },
            "End": true
          },
          "InstanceBlocked": {
            "Type": "Pass",
            "Parameters": {
              "instanceId.$": "$.instanceId",
              "executionStatus": "Blocked-PermissionDenied",
              "rcaSummary": "Install permission not granted - operation blocked before touching instance",
              "backupTaken.$": "$.takeBackup",
              "restoreTriggered": false
            },
            "End": true
          },
          "InstanceFailedNoBackup": {
            "Type": "Pass",
            "Parameters": {
              "instanceId.$": "$.instanceId",
              "executionStatus": "Failed-NoBackupAvailable",
              "rcaSummary.$": "$.rcaResult.rcaSummary",
              "backupTaken": false,
              "restoreTriggered": false
            },
            "End": true
          },
          "InstanceFailedApprovalTimeout": {
            "Type": "Pass",
            "Parameters": {
              "instanceId.$": "$.instanceId",
              "executionStatus": "Failed-RestoreApprovalTimedOut",
              "rcaSummary.$": "$.rcaResult.rcaSummary",
              "backupTaken": true,
              "restoreTriggered": false
            },
            "End": true
          },
          "InstanceFailedRestoreRejected": {
            "Type": "Pass",
            "Parameters": {
              "instanceId.$": "$.instanceId",
              "executionStatus": "Failed-RestoreRejected",
              "rcaSummary.$": "$.rcaResult.rcaSummary",
              "backupTaken": true,
              "restoreTriggered": false
            },
            "End": true
          },
          "InstanceRestored": {
            "Type": "Pass",
            "Parameters": {
              "instanceId.$": "$.instanceId",
              "executionStatus": "Failed-RestoredFromBackup",
              "rcaSummary.$": "$.rcaResult.rcaSummary",
              "backupTaken": true,
              "restoreTriggered": true
            },
            "End": true
          }
        }
      },
      "Next": "BuildExecutionReport"
    },
    "BuildExecutionReport": {
      "Type": "Task",
      "Resource": "${dispatcher_arn}",
      "Parameters": {
        "task": "report_builder",
        "operation.$": "$.operation",
        "environmentTag.$": "$.environmentTag",
        "compliant.$": "$.compliant",
        "nonCompliant.$": "$.processedInstances",
        "executionId.$": "$.executionId"
      },
      "End": true
    }
  }
}

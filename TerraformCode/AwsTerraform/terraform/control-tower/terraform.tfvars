aws_region = "us-east-1"

landing_zone_version = "4.0"

manifest_json = <<JSON
{
  "accessManagement": {
    "enabled": false
  },
  "securityRoles": {
    "accountId": "152500409784",
    "enabled": true
  },
  "backup": {
    "enabled": false
  },
  "governedRegions": [
    "us-east-2",
    "us-east-1"
  ],
  "config": {
    "accountId": "152500409784",
    "configurations": {
      "loggingBucket": {
        "retentionDays": 365
      },
      "accessLoggingBucket": {
        "retentionDays": 3650
      }
    },
    "enabled": true
  },
  "centralizedLogging": {
    "accountId": "038269111064",
    "configurations": {
      "loggingBucket": {
        "retentionDays": 365
      },
      "accessLoggingBucket": {
        "retentionDays": 3650
      }
    },
    "enabled": true
  }
}
JSON

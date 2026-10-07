aws_region = "us-east-1"

organization_id = "o-tiz1ddrmwn"

management_account_id = "211811255273"

organizational_units = {
  security = {
    name = "Security OU"
  }

  infrastructure = {
    name = "Infrastructure OU"
  }

  workloads = {
    name = "Workloads OU"
  }
}

accounts = {
  network = {
    name      = "Network"
    email     = "arpitchouksey18+network@gmail.com"
    parent_ou = "infrastructure"
  }

  shared_services = {
    name      = "SharedServices"
    email     = "arpitchouksey18+sharedservices@gmail.com"
    parent_ou = "infrastructure"
  }

  log_archive = {
    name      = "LogArchive"
    email     = "arpitchouksey18+logarchive@gmail.com"
    parent_ou = "security"
  }

  security = {
    name      = "Security"
    email     = "arpitchouksey18+security@gmail.com"
    parent_ou = "security"
  }

  non_production = {
    name      = "NonProduction"
    email     = "arpitchouksey18+nonproduction@gmail.com"
    parent_ou = "workloads"
  }

  production = {
    name      = "Production"
    email     = "arpitchouksey18+production@gmail.com"
    parent_ou = "workloads"
  }
}

service_control_policies = {
  deny_leaving_organization = {
    name        = "DenyLeavingOrganization"
    description = "Prevent member accounts from leaving the AWS Organization."

    content = <<JSON
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyLeaveOrganization",
      "Effect": "Deny",
      "Action": [
        "organizations:LeaveOrganization"
      ],
      "Resource": "*"
    }
  ]
}
JSON

    targets = [
      "r-pyfi"
    ]
  }

  deny_cloudtrail_disable_delete = {
    name        = "DenyCloudTrailDisableOrDelete"
    description = "Prevent member accounts from disabling or deleting CloudTrail logging."

    content = <<JSON
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyCloudTrailDisableOrDelete",
      "Effect": "Deny",
      "Action": [
        "cloudtrail:StopLogging",
        "cloudtrail:DeleteTrail"
      ],
      "Resource": "*"
    }
  ]
}
JSON

    targets = []
  }
}

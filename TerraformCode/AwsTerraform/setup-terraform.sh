#!/bin/bash

set -e

ROOT="terraform"

echo "Creating enterprise Terraform structure..."

# ============================================================
# DIRECTORIES
# ============================================================

mkdir -p "$ROOT"/modules/{organization,control-tower,identity-center,account-baseline,networking,security,logging,shared-services,compute,eks,data,edge,observability,disaster-recovery,automation,governance}

mkdir -p "$ROOT"/{org,control-tower,identity-center,configs,scripts,docs}

for account in management security log-archive network shared-services production non-production; do
    mkdir -p "$ROOT/accounts/$account/us-east-1"
done


# ============================================================
# ORGANIZATION MODULE
# ============================================================

cat > "$ROOT/modules/organization/variables.tf" <<'EOF'
variable "organization_id" {
  type = string
}

variable "management_account_id" {
  type = string
}

variable "organizational_units" {
  type = map(object({
    name = string
  }))
}

variable "accounts" {
  type = map(object({
    name              = string
    email             = string
    parent_ou         = string
    close_on_deletion = optional(bool, false)
  }))
}

variable "service_control_policies" {
  type = map(object({
    name        = string
    description = optional(string)
    content     = string
    targets     = list(string)
  }))
  default = {}
}
EOF

cat > "$ROOT/modules/organization/main.tf" <<'EOF'
data "aws_organizations_organization" "current" {}

resource "aws_organizations_organization" "this" {
  aws_service_access_principals = [
    "cloudtrail.amazonaws.com",
    "config.amazonaws.com",
    "sso.amazonaws.com"
  ]

  enabled_policy_types = [
    "SERVICE_CONTROL_POLICY"
  ]

  feature_set = "ALL"
}

resource "aws_organizations_organizational_unit" "this" {
  for_each = var.organizational_units

  name      = each.value.name
  parent_id = data.aws_organizations_organization.current.roots[0].id
}

resource "aws_organizations_account" "this" {
  for_each = var.accounts

  name              = each.value.name
  email             = each.value.email
  parent_id         = aws_organizations_organizational_unit.this[each.value.parent_ou].id
  close_on_deletion = each.value.close_on_deletion
}

resource "aws_organizations_policy" "this" {
  for_each = var.service_control_policies

  name        = each.value.name
  description = each.value.description
  content     = each.value.content
  type        = "SERVICE_CONTROL_POLICY"
}

resource "aws_organizations_policy_attachment" "this" {
  for_each = {
    for item in flatten([
      for policy_key, policy in var.service_control_policies : [
        for target in policy.targets : {
          key        = "${policy_key}-${target}"
          policy_key = policy_key
          target     = target
        }
      ]
    ]) : item.key => item
  }

  policy_id = aws_organizations_policy.this[each.value.policy_key].id
  target_id = each.value.target
}
EOF

cat > "$ROOT/modules/organization/outputs.tf" <<'EOF'
output "organization_id" {
  value = data.aws_organizations_organization.current.id
}

output "root_id" {
  value = data.aws_organizations_organization.current.roots[0].id
}

output "organizational_units" {
  value = {
    for key, ou in aws_organizations_organizational_unit.this :
    key => ou.id
  }
}

output "accounts" {
  value = {
    for key, account in aws_organizations_account.this :
    key => account.id
  }
}

output "policies" {
  value = {
    for key, policy in aws_organizations_policy.this :
    key => policy.id
  }
}
EOF


# ============================================================
# CONTROL TOWER MODULE
# ============================================================

cat > "$ROOT/modules/control-tower/variables.tf" <<'EOF'
variable "home_region" {
  type = string
}

variable "governed_regions" {
  type = list(string)
}

variable "landing_zone_version" {
  type = string
}

variable "automatic_account_enrollment" {
  type    = bool
  default = true
}

variable "service_integrations" {
  type = object({
    config                   = bool
    cloudtrail               = bool
    identity_center          = bool
    backup                   = bool
    service_integration_ou   = string
    config_aggregator_account = string
    cloudtrail_account       = string
  })
}
EOF

cat > "$ROOT/modules/control-tower/main.tf" <<'EOF'
resource "aws_controltower_landing_zone" "this" {
  version = var.landing_zone_version

  manifest_json = jsonencode({
    governedRegions = var.governed_regions

    centralizedLogging = {
      enabled = var.service_integrations.cloudtrail

      accountId = var.service_integrations.cloudtrail_account

      configurations = {
        loggingBucket = {
          retentionDays = 3650
        }
      }
    }

    accessManagement = {
      enabled = var.service_integrations.identity_center
    }
  })
}
EOF

cat > "$ROOT/modules/control-tower/outputs.tf" <<'EOF'
output "landing_zone_id" {
  value = aws_controltower_landing_zone.this.id
}

output "landing_zone_version" {
  value = var.landing_zone_version
}
EOF


# ============================================================
# IDENTITY CENTER MODULE
# ============================================================

cat > "$ROOT/modules/identity-center/variables.tf" <<'EOF'
variable "identity_store_id" {
  type = string
}

variable "permission_sets" {
  type = map(object({
    name             = string
    description      = string
    session_duration = optional(string, "PT1H")
  }))
}

variable "account_assignments" {
  type = list(object({
    permission_set_arn = string
    principal_id       = string
    principal_type     = string
    target_id          = string
    target_type        = string
  }))
  default = []
}
EOF

cat > "$ROOT/modules/identity-center/main.tf" <<'EOF'
resource "aws_ssoadmin_permission_set" "this" {
  for_each = var.permission_sets

  name             = each.value.name
  description      = each.value.description
  instance_arn     = data.aws_ssoadmin_instances.this.arns[0]
  session_duration = each.value.session_duration
}

data "aws_ssoadmin_instances" "this" {}

resource "aws_ssoadmin_account_assignment" "this" {
  for_each = {
    for assignment in var.account_assignments :
    "${assignment.principal_id}-${assignment.target_id}-${assignment.permission_set_arn}" => assignment
  }

  instance_arn       = data.aws_ssoadmin_instances.this.arns[0]
  permission_set_arn = each.value.permission_set_arn
  principal_id       = each.value.principal_id
  principal_type     = each.value.principal_type
  target_id          = each.value.target_id
  target_type        = each.value.target_type
}
EOF

cat > "$ROOT/modules/identity-center/outputs.tf" <<'EOF'
output "identity_center_instance_arn" {
  value = data.aws_ssoadmin_instances.this.arns[0]
}

output "permission_sets" {
  value = {
    for key, permission_set in aws_ssoadmin_permission_set.this :
    key => permission_set.arn
  }
}
EOF


# ============================================================
# GENERIC ACCOUNT BASELINE MODULE
# ============================================================

cat > "$ROOT/modules/account-baseline/variables.tf" <<'EOF'
variable "account_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "region" {
  type = string
}

variable "enable_config" {
  type    = bool
  default = false
}

variable "enable_cloudtrail" {
  type    = bool
  default = false
}
EOF

cat > "$ROOT/modules/account-baseline/main.tf" <<'EOF'
locals {
  account_name = var.account_name
  environment  = var.environment
  region       = var.region
}
EOF

cat > "$ROOT/modules/account-baseline/outputs.tf" <<'EOF'
output "account_name" {
  value = local.account_name
}

output "environment" {
  value = local.environment
}

output "region" {
  value = local.region
}
EOF


# ============================================================
# PLACEHOLDER ENTERPRISE MODULES
# ============================================================

for module in networking security logging shared-services compute eks data edge observability disaster-recovery automation governance; do

cat > "$ROOT/modules/$module/variables.tf" <<EOF
variable "name" {
  type = string
}

variable "environment" {
  type = string
}

variable "region" {
  type = string
}
EOF

cat > "$ROOT/modules/$module/main.tf" <<EOF
locals {
  name        = var.name
  environment = var.environment
  region      = var.region
}
EOF

cat > "$ROOT/modules/$module/outputs.tf" <<EOF
output "name" {
  value = local.name
}

output "environment" {
  value = local.environment
}

output "region" {
  value = local.region
}
EOF

done


# ============================================================
# PROVIDER
# ============================================================

cat > "$ROOT/org/providers.tf" <<'EOF'
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
EOF


# ============================================================
# ORGANIZATION ROOT
# ============================================================

cat > "$ROOT/org/variables.tf" <<'EOF'
variable "aws_region" {
  type = string
}

variable "organization_id" {
  type = string
}

variable "management_account_id" {
  type = string
}

variable "organizational_units" {
  type = map(object({
    name = string
  }))
}

variable "accounts" {
  type = map(object({
    name              = string
    email             = string
    parent_ou         = string
    close_on_deletion = optional(bool, false)
  }))
}

variable "service_control_policies" {
  type = map(object({
    name        = string
    description = optional(string)
    content     = string
    targets     = list(string)
  }))
  default = {}
}
EOF

cat > "$ROOT/org/main.tf" <<'EOF'
module "organization" {
  source = "../modules/organization"

  organization_id       = var.organization_id
  management_account_id = var.management_account_id
  organizational_units  = var.organizational_units
  accounts              = var.accounts
  service_control_policies = var.service_control_policies
}
EOF

cat > "$ROOT/org/outputs.tf" <<'EOF'
output "organization_id" {
  value = module.organization.organization_id
}

output "root_id" {
  value = module.organization.root_id
}

output "organizational_units" {
  value = module.organization.organizational_units
}

output "accounts" {
  value = module.organization.accounts
}

output "policies" {
  value = module.organization.policies
}
EOF

cat > "$ROOT/org/terraform.tfvars" <<'EOF'
aws_region            = "us-east-1"
organization_id       = "o-tiz1ddrmwn"
management_account_id = "211811255273"

organizational_units = {
  security = {
    name = "Security"
  }

  infrastructure = {
    name = "Infrastructure"
  }

  workloads = {
    name = "Workloads"
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
    description = "Prevent member accounts from leaving the AWS Organization"

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

    targets = []
  }

  deny_cloudtrail_disable_delete = {
    name        = "DenyCloudTrailDisableOrDelete"
    description = "Prevent CloudTrail from being disabled or deleted"

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
EOF

cat > "$ROOT/org/imports.tf" <<'EOF'
# Existing Organization
# Uncomment after verifying the configuration.

# import {
#   to = module.organization.aws_organizations_organization.this
#   id = "o-tiz1ddrmwn"
# }

# Existing OUs and accounts should be imported after
# discovering their exact AWS resource IDs.
#
# Example:
#
# import {
#   to = module.organization.aws_organizations_organizational_unit.this["security"]
#   id = "ou-xxxxxxxxxxxxxxxx"
# }
#
# import {
#   to = module.organization.aws_organizations_account.this["network"]
#   id = "360734036001"
# }
EOF


# ============================================================
# CONTROL TOWER ROOT
# ============================================================

cat > "$ROOT/control-tower/providers.tf" <<'EOF'
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
EOF

cat > "$ROOT/control-tower/variables.tf" <<'EOF'
variable "aws_region" {
  type = string
}

variable "home_region" {
  type = string
}

variable "governed_regions" {
  type = list(string)
}

variable "landing_zone_version" {
  type = string
}

variable "automatic_account_enrollment" {
  type    = bool
  default = true
}

variable "service_integrations" {
  type = object({
    config                    = bool
    cloudtrail                = bool
    identity_center           = bool
    backup                    = bool
    service_integration_ou    = string
    config_aggregator_account = string
    cloudtrail_account        = string
  })
}
EOF

cat > "$ROOT/control-tower/main.tf" <<'EOF'
module "control_tower" {
  source = "../modules/control-tower"

  home_region                = var.home_region
  governed_regions           = var.governed_regions
  landing_zone_version       = var.landing_zone_version
  automatic_account_enrollment = var.automatic_account_enrollment
  service_integrations       = var.service_integrations
}
EOF

cat > "$ROOT/control-tower/outputs.tf" <<'EOF'
output "landing_zone_id" {
  value = module.control_tower.landing_zone_id
}
EOF

cat > "$ROOT/control-tower/terraform.tfvars" <<'EOF'
aws_region          = "us-east-1"
home_region         = "us-east-1"
governed_regions    = ["us-east-1", "us-east-2"]
landing_zone_version = "4.0"

automatic_account_enrollment = true

service_integrations = {
  config                    = true
  cloudtrail                = true
  identity_center           = true
  backup                    = false
  service_integration_ou    = "Security"
  config_aggregator_account = "152500409784"
  cloudtrail_account        = "038269111064"
}
EOF


# ============================================================
# IDENTITY CENTER ROOT
# ============================================================

cat > "$ROOT/identity-center/providers.tf" <<'EOF'
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
EOF

cat > "$ROOT/identity-center/variables.tf" <<'EOF'
variable "aws_region" {
  type = string
}

variable "identity_store_id" {
  type = string
}

variable "permission_sets" {
  type = map(object({
    name             = string
    description      = string
    session_duration = optional(string, "PT1H")
  }))
}
EOF

cat > "$ROOT/identity-center/main.tf" <<'EOF'
module "identity_center" {
  source = "../modules/identity-center"

  identity_store_id = var.identity_store_id
  permission_sets   = var.permission_sets
}
EOF

cat > "$ROOT/identity-center/outputs.tf" <<'EOF'
output "identity_center_instance_arn" {
  value = module.identity_center.identity_center_instance_arn
}

output "permission_sets" {
  value = module.identity_center.permission_sets
}
EOF

cat > "$ROOT/identity-center/terraform.tfvars" <<'EOF'
aws_region       = "us-east-1"
identity_store_id = "d-xxxxxxxxxx"

permission_sets = {
  administrator = {
    name        = "Administrator"
    description = "Administrator access for platform administration"
  }

  read_only = {
    name        = "ReadOnly"
    description = "Read-only access"
  }
}
EOF


# ============================================================
# ACCOUNT ROOTS
# ============================================================

for account in management security log-archive network shared-services production non-production; do

    case "$account" in
        management)
            ENVIRONMENT="management"
            ;;
        security)
            ENVIRONMENT="security"
            ;;
        log-archive)
            ENVIRONMENT="logging"
            ;;
        network)
            ENVIRONMENT="network"
            ;;
        shared-services)
            ENVIRONMENT="shared-services"
            ;;
        production)
            ENVIRONMENT="production"
            ;;
        non-production)
            ENVIRONMENT="non-production"
            ;;
    esac

    DIR="$ROOT/accounts/$account/us-east-1"

    cat > "$DIR/providers.tf" <<'EOF'
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
EOF

    cat > "$DIR/variables.tf" <<'EOF'
variable "aws_region" {
  type = string
}

variable "account_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "account_id" {
  type = string
}
EOF

    cat > "$DIR/main.tf" <<'EOF'
module "account_baseline" {
  source = "../../../modules/account-baseline"

  account_name = var.account_name
  environment  = var.environment
  region       = var.aws_region
}
EOF

    cat > "$DIR/outputs.tf" <<'EOF'
output "account_name" {
  value = module.account_baseline.account_name
}

output "environment" {
  value = module.account_baseline.environment
}

output "region" {
  value = module.account_baseline.region
}
EOF

    cat > "$DIR/terraform.tfvars" <<EOF
aws_region  = "us-east-1"
account_name = "$account"
environment = "$ENVIRONMENT"
account_id  = ""
EOF

done


# ============================================================
# DEPLOY-ALL SCRIPT
# ============================================================

cat > "$ROOT/scripts/deploy-all.sh" <<'EOF'
#!/bin/bash

set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "=========================================="
echo " Enterprise Terraform Deployment"
echo "=========================================="

run_terraform() {
    local DIR="$1"

    echo ""
    echo "=========================================="
    echo "Processing: $DIR"
    echo "=========================================="

    cd "$ROOT/$DIR"

    terraform init
    terraform validate
    terraform plan

    read -p "Apply $DIR? (yes/no): " CONFIRM

    if [ "$CONFIRM" = "yes" ]; then
        terraform apply -auto-approve
    else
        echo "Skipping $DIR"
    fi
}

# ------------------------------------------------------------
# Phase 1 - Organization
# ------------------------------------------------------------

run_terraform "org"

# ------------------------------------------------------------
# Phase 2 - Control Tower
# ------------------------------------------------------------

run_terraform "control-tower"

# ------------------------------------------------------------
# Phase 3 - Identity Center
# ------------------------------------------------------------

run_terraform "identity-center"

# ------------------------------------------------------------
# Phase 4 - Account Baselines
# ------------------------------------------------------------

for ACCOUNT in \
    management \
    security \
    log-archive \
    network \
    shared-services \
    production \
    non-production
do
    run_terraform "accounts/$ACCOUNT/us-east-1"
done

echo ""
echo "=========================================="
echo " Deployment completed"
echo "=========================================="
EOF

chmod +x "$ROOT/scripts/deploy-all.sh"


# ============================================================
# GITIGNORE
# ============================================================

cat > "$ROOT/.gitignore" <<'EOF'
.terraform/
.terraform.lock.hcl
terraform.tfstate
terraform.tfstate.*
*.tfstate
*.tfstate.*
crash.log
crash.*.log
override.tf
override.tf.json
*_override.tf
*_override.tf.json
EOF


# ============================================================
# README
# ============================================================

cat > "$ROOT/README.md" <<'EOF'
# Enterprise AWS Terraform Architecture

## Structure

- `modules/` - reusable Terraform modules
- `org/` - AWS Organizations
- `control-tower/` - AWS Control Tower
- `identity-center/` - IAM Identity Center
- `accounts/` - account and regional infrastructure
- `configs/` - architecture configuration
- `scripts/` - automation
- `docs/` - architecture documentation

## Deployment

Each root module has its own Terraform state.

Initialize and validate individually:

```bash
cd org
terraform init
terraform validate
terraform plan

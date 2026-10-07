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

# Enterprise Master Networking Architecture

Production-grade multi-account cloud networking architecture built with **AWS, Azure, Terraform, and hybrid connectivity patterns**.

This project is designed as an enterprise/SRE-focused reference implementation covering:

- AWS Organizations
- AWS Control Tower
- IAM Identity Center
- Multi-account architecture
- AWS VPC
- AWS VPC IPAM
- Transit Gateway
- AWS Cloud WAN
- Hybrid connectivity
- Azure ↔ AWS connectivity
- Site-to-Site VPN
- BGP / Static Routing
- Network Firewall
- VPC Endpoints
- AWS PrivateLink
- Route 53 / DNS Resolver
- Cross-account networking
- Workload connectivity
- Edge / ingress architecture
- High Availability / Disaster Recovery
- Observability
- Terraform Infrastructure as Code
- Terraform import and reconciliation
- Operational troubleshooting

---

# 1. Project Objective

The objective of this project is to design and implement a production-grade enterprise networking foundation using a multi-account cloud architecture.

The architecture separates governance, security, networking, shared services, and workloads into dedicated AWS accounts.

```text
                         AWS Organization
                                |
             +------------------+------------------+
             |                  |                  |
          Security         Infrastructure       Workloads
             |                  |                  |
       +-----+-----+      +-----+------+      +----+-----+
       |           |      |            |      |          |
   Security    LogArchive Network   Shared   Production NonProd
                              |      Services
                              |
                    Master Networking
                              |
          +-------------------+-------------------+
          |                   |                   |
         IPAM                TGW              Cloud WAN
          |                   |                   |
          +-------------------+-------------------+
                              |
                  Hybrid / Cross-Account Network
                              |
              +---------------+---------------+
              |                               |
            Azure                         On-Prem

2. Architecture Principles

The project follows these principles:

Multi-account isolation
Centralized networking
Centralized governance
Least privilege
No overlapping CIDRs
High availability across Availability Zones
Centralized connectivity
Controlled cross-account communication
Infrastructure as Code
Terraform reconciliation
Observable network traffic
Production-grade troubleshooting
Disaster recovery readiness
Zero-drift infrastructure
3. AWS Account Architecture

The AWS organization is logically divided into:

AWS Organization
|
+-- Security OU
|   +-- Security Account
|   +-- Log Archive Account
|
+-- Infrastructure OU
|   +-- Network Account
|   +-- Shared Services Account
|
+-- Workloads OU
    +-- Production Account
    +-- Non-Production Account
Account Responsibilities
Account	Responsibility
Management	AWS Organizations, governance and billing
Security	Security controls and security services
Log Archive	Centralized logging and audit data
Network	Central networking infrastructure
Shared Services	Enterprise shared services
Production	Production workloads
Non-Production	Development/Test/Staging workloads
4. Master Networking Architecture

The central networking architecture contains:

                    Enterprise Network
                           |
          +----------------+----------------+
          |                |                |
        IPAM              TGW            Cloud WAN
          |                |                |
          |         +------+-------+        |
          |         |              |        |
       VPC CIDRs   Workloads    Hybrid      |
                    VPCs       Connectivity |
          |                        |         |
          +------------------------+---------+
                                   |
                         Network Inspection
                                   |
                    +--------------+--------------+
                    |                             |
                Internet                       Hybrid
                    |                             |
               IGW / NAT                  VPN / BGP
                                                |
                                          Azure / On-Prem
5. Repository Structure
NetworkingMasterCode/
|
+-- AzureTerraform/
|   |
|   +-- accounts/
|   |   +-- azure/
|   |       +-- hybrid-networking/
|   |           +-- centralindia/
|   |               +-- main.tf
|   |               +-- variables.tf
|   |               +-- outputs.tf
|   |               +-- providers.tf
|   |               +-- terraform.tfvars
|   |
|   +-- modules/
|       +-- azure-hybrid-networking/
|           +-- main.tf
|           +-- variables.tf
|           +-- outputs.tf
|
+-- Terraform/
    |
    +-- setup-terraform.sh
    |
    +-- terraform/
        |
        +-- accounts/
        |   +-- management/
        |   +-- security/
        |   +-- log-archive/
        |   +-- network/
        |   +-- shared-services/
        |   +-- production/
        |   +-- non-production/
        |
        +-- configs/
        |
        +-- control-tower/
        |
        +-- identity-center/
        |
        +-- modules/
        |   +-- account-baseline/
        |   +-- automation/
        |   +-- compute/
        |   +-- control-tower/
        |   +-- data/
        |   +-- disaster-recovery/
        |   +-- edge/
        |   +-- eks/
        |   +-- governance/
        |   +-- identity-center/
        |   +-- logging/
        |   +-- networking/
        |   +-- observability/
        |   +-- organization/
        |   +-- security/
        |   +-- shared-services/
        |
        +-- org/
        |
        +-- scripts/
        |   +-- deploy-all.sh
        |
        +-- README.md
6. Prerequisites
Local Environment

Recommended environment:

macOS / Linux
Git
Terraform
AWS CLI
Azure CLI
jq

Optional:

tree
kubectl
helm
7. Install AWS CLI
macOS

Using Homebrew:

brew install awscli

Verify:

aws --version

Example:

aws-cli/2.x.x
8. Install Terraform

Using Homebrew:

brew tap hashicorp/tap
brew install hashicorp/tap/terraform

Verify:

terraform version

The project was developed/tested with Terraform 1.x.

Always verify the exact required provider versions from:

versions.tf
providers.tf
9. Install Azure CLI
brew install azure-cli

Verify:

az version

Login:

az login

Verify the active subscription:

az account show

List subscriptions:

az account list -o table

Select the required subscription:

az account set --subscription "<SUBSCRIPTION_ID>"
10. AWS Authentication

Configure AWS CLI profiles.

Example:

aws configure --profile management
aws configure --profile network
aws configure --profile security
aws configure --profile production

Do not store AWS access keys, secret keys, session tokens, or passwords inside the Git repository.

Recommended authentication mechanisms:

AWS IAM Identity Center
AWS SSO
Short-lived credentials
AWS CLI profiles
IAM roles
Environment-based temporary credentials
11. Verify AWS Identity

Before running Terraform:

aws sts get-caller-identity --profile management

For Network:

aws sts get-caller-identity --profile network

Expected structure:

{
    "UserId": "...",
    "Account": "...",
    "Arn": "..."
}

Always verify the account before performing infrastructure operations.

12. Configure Terraform

Move to the Terraform directory:

cd Terraform/terraform

Initialize the required working directory.

For example:

cd accounts/network/us-east-1
terraform init

For management:

cd accounts/management/us-east-1
terraform init

For organization:

cd org
terraform init

For Control Tower:

cd control-tower
terraform init

For Identity Center:

cd identity-center
terraform init
13. Terraform Initialization

Standard workflow:

terraform init

Upgrade providers only when intentionally required:

terraform init -upgrade

Do not blindly upgrade providers in a production environment.

14. Terraform Formatting

Run:

terraform fmt -recursive

Check formatting:

terraform fmt -check -recursive
15. Terraform Validation

Run:

terraform validate

Expected:

Success! The configuration is valid.
16. Terraform Plan

Always review the plan before applying:

terraform plan

For a specific variables file:

terraform plan -var-file="terraform.tfvars"

Never apply infrastructure without reviewing the plan.

17. Terraform Apply

After validation:

terraform apply

Or:

terraform apply -var-file="terraform.tfvars"

Review the proposed changes before confirming.

18. Terraform Workflow

The standard workflow used in this project is:

AWS Console
     |
     v
Create / Configure
     |
     v
Verify Resource
     |
     v
Capture AWS IDs / ARNs
     |
     v
Terraform Module
     |
     v
Terraform Import
     |
     v
terraform fmt
     |
     v
terraform validate
     |
     v
terraform plan
     |
     v
terraform apply
     |
     v
Terraform Reconciliation
     |
     v
0 Add / 0 Change / 0 Destroy

The goal is to avoid duplicate resources and reconcile Terraform with the actual AWS infrastructure.

19. Terraform Import

When infrastructure already exists:

terraform import <resource_address> <resource_id>

Example:

terraform import \
  aws_vpc.example \
  vpc-xxxxxxxx

Then:

terraform plan

Continue updating the Terraform code until the configuration accurately represents the existing infrastructure.

20. Zero-Drift Validation

The desired final Terraform result is:

Plan: 0 to add, 0 to change, 0 to destroy.

This confirms that Terraform configuration and deployed infrastructure are reconciled.

21. AWS Organization Terraform

Organization-level Terraform is located at:

Terraform/terraform/org/

Main files:

main.tf
variables.tf
outputs.tf
providers.tf
terraform.tfvars
imports.tf

Initialize:

cd Terraform/terraform/org
terraform init

Validate:

terraform validate

Plan:

terraform plan

Apply:

terraform apply
22. Control Tower Terraform

Location:

Terraform/terraform/control-tower/

Contains:

main.tf
variables.tf
outputs.tf
providers.tf
terraform.tfvars

Control Tower should be treated as a governance/control-plane component rather than normal workload infrastructure.

23. IAM Identity Center Terraform

Location:

Terraform/terraform/identity-center/

Responsibilities include:

Identity Center configuration
Users
Permission sets
Account assignments
Cross-account administrative access
24. Network Account Terraform

Location:

Terraform/terraform/accounts/network/us-east-1/

Contains networking-specific configuration such as:

main.tf
azure-connectivity.tf
transit-gateway.tf
variables.tf
outputs.tf
providers.tf
terraform.tfvars

This directory represents the central AWS networking layer.

25. Terraform Modules

Reusable modules are located under:

Terraform/terraform/modules/

Major modules include:

account-baseline
automation
compute
control-tower
data
disaster-recovery
edge
eks
governance
identity-center
logging
networking
observability
organization
security
shared-services

Modules should remain reusable and should avoid hardcoded environment-specific values.

26. Variable Management

Environment-specific configuration belongs in:

terraform.tfvars

Reusable variables belong in:

variables.tf

Outputs belong in:

outputs.tf

Provider configuration belongs in:

providers.tf

Avoid hardcoding:

Account IDs
Region
CIDRs
Resource names
ARNs
Environment-specific values
Credentials
Secrets
27. Azure Hybrid Networking

Azure Terraform is located at:

AzureTerraform/

The current structure:

AzureTerraform/
|
+-- accounts/
|   +-- azure/
|       +-- hybrid-networking/
|           +-- centralindia/
|               +-- main.tf
|               +-- variables.tf
|               +-- outputs.tf
|               +-- providers.tf
|               +-- terraform.tfvars
|
+-- modules/
    +-- azure-hybrid-networking/
        +-- main.tf
        +-- variables.tf
        +-- outputs.tf
28. Azure ↔ AWS Connectivity

The target hybrid architecture is:

                    Azure
                      |
                 Azure VNet
                      |
               VPN Gateway
                      |
                  IPsec/IKE
                      |
                  Internet
                      |
             AWS Customer Gateway
                      |
              AWS Site-to-Site VPN
                      |
                Transit Gateway
                      |
                  Cloud WAN
                      |
        +-------------+-------------+
        |             |             |
      Network     SharedServices  Workloads
                                  |
                           +------+------+
                           |             |
                       Production     NonProd

The design should consider:

CIDR allocation
BGP ASN
VPN tunnels
Customer Gateway
AWS Site-to-Site VPN
Transit Gateway
Cloud WAN
Route propagation
Return paths
Security controls
High availability
29. CIDR Strategy

CIDR planning must happen before creating additional VPCs.

The enterprise address space should accommodate:

Network
Shared Services
Production
Non-Production
Inspection
Hybrid Connectivity
On-Premises
Azure
Future VPCs
Future Regions

The most important rule:

NO CIDR OVERLAP

AWS IPAM should be used as the source of truth for AWS VPC address allocation.

30. Transit Gateway

The Transit Gateway layer provides centralized connectivity between:

VPCs
|
+-- Production
+-- Non-Production
+-- Shared Services
+-- Network
+-- VPN
+-- Hybrid Connectivity

Key components:

Transit Gateway
TGW route tables
TGW attachments
Route propagation
Static routes
Cross-account attachments
RAM sharing
31. AWS Cloud WAN

Cloud WAN provides centralized global network connectivity.

Conceptually:

Cloud WAN
|
+-- Enterprise Segment
|
+-- Network Segment
|
+-- Production Segment
|
+-- NonProduction Segment
|
+-- SharedServices Segment

Routing policies should explicitly define which segments are allowed to communicate.

32. Network Security

The architecture supports centralized inspection using:

Network Firewall
+
Inspection VPC
+
Transit Gateway
+
Cloud WAN

Traffic flows should be designed intentionally.

Example:

Workload
   |
   v
TGW / Cloud WAN
   |
   v
Inspection
   |
   v
Network Firewall
   |
   v
Destination
33. Private Connectivity

The project covers:

VPC Endpoints
Interface endpoints
Gateway endpoints
PrivateLink

Used for private service-to-service connectivity without exposing services publicly.

34. DNS Architecture

The project covers:

Route 53
|
+-- Private Hosted Zones
|
+-- Route 53 Resolver
    |
    +-- Inbound Endpoints
    |
    +-- Outbound Endpoints
    |
    +-- Resolver Rules

DNS forwarding should be designed for:

AWS workloads
Azure
On-Premises
Shared Services
Enterprise domains
35. High Availability

Networking components should be designed across multiple Availability Zones wherever supported.

Examples:

AZ-1                  AZ-2                  AZ-3
 |                     |                     |
Public Subnet       Public Subnet        Public Subnet
Private Subnet      Private Subnet       Private Subnet
TGW Subnet          TGW Subnet           TGW Subnet
Firewall            Firewall             Firewall

Avoid single points of failure.

36. Observability

The architecture should provide visibility into:

VPC Flow Logs
CloudWatch
CloudTrail
AWS Config
Network Firewall logs
Transit Gateway metrics
VPN tunnel status
Cloud WAN connectivity
Route propagation
NAT Gateway metrics
ALB/NLB metrics
DNS Resolver logs
37. Network Troubleshooting Methodology

When connectivity fails, follow this order:

1. Identify source
       |
2. Identify destination
       |
3. Verify source subnet
       |
4. Verify route table
       |
5. Verify TGW attachment
       |
6. Verify TGW route table
       |
7. Verify Cloud WAN segment
       |
8. Verify propagation
       |
9. Verify Network Firewall
       |
10. Verify Security Group
       |
11. Verify NACL
       |
12. Verify DNS
       |
13. Verify return path
       |
14. Check VPC Flow Logs
       |
15. Check CloudWatch / service logs

The key principle is:

Always validate the complete forward and return path.

38. Cross-Account Connectivity

Cross-account networking can involve:

AWS RAM
Transit Gateway
Cloud WAN
VPC Attachments
Route Tables
IAM
Resource Policies
Security Groups
Network Firewall

Every cross-account relationship should be explicitly documented and validated.

39. Security Guidelines

Never commit:

AWS Access Keys
AWS Secret Keys
Session Tokens
Passwords
Private Keys
API Tokens
Secrets
Production Credentials

Do not hardcode credentials in:

*.tf
*.tfvars
*.sh
README.md

Use:

AWS SSO
IAM Roles
Temporary Credentials
AWS Secrets Manager
Environment Variables

where appropriate.

40. Git Safety

Before committing:

git status

Check for Terraform state:

find . -name "*.tfstate*" -print

Check Terraform working directories:

find . -type d -name ".terraform" -print

Check for potential secrets:

git grep -nEi \
'aws_access_key_id|aws_secret_access_key|aws_session_token|password|secret|token|api[_-]?key'

Review all results before pushing.

41. Terraform Files That Should Not Be Committed

Normally exclude:

.terraform/
*.tfstate
*.tfstate.*
crash.log
crash.*.log
.terraform.tfstate.lock.info

A typical .gitignore:

# Terraform
**/.terraform/
*.tfstate
*.tfstate.*
crash.log
crash.*.log
.terraform.tfstate.lock.info

# Secrets / environment variables
*.tfvars
*.tfvars.json

# macOS
.DS_Store

# IDE
.idea/
.vscode/
*.swp
*.swo

If a terraform.tfvars file contains only safe, non-sensitive configuration and is intentionally part of the project, it may be committed after review.

42. Terraform State

Terraform state is environment-specific.

Production state should preferably be stored remotely using:

S3
+
DynamoDB / locking mechanism

or the current Terraform-supported remote state/locking architecture used by the organization.

For this reference project, local state may have been used during experimentation.

Do not commit local state files into Git.

43. Deployment Order

Recommended implementation order:

Phase 1
AWS Organization
        |
Phase 2
Landing Zone / Governance
        |
Phase 3
Network Account
        |
Phase 4
IPAM / Core VPC
        |
Phase 5
Transit Gateway
        |
Phase 6
Cloud WAN
        |
Phase 7
Hybrid Connectivity
        |
Phase 8
Network Firewall
        |
Phase 9
Private Connectivity
        |
Phase 10
DNS
        |
Phase 11
Workload Connectivity
        |
Phase 12
Edge / Ingress
        |
Phase 13
Observability
        |
Phase 14
HA / DR
        |
Phase 15
Terraform Reconciliation
44. Standard Terraform Commands
Initialize
terraform init
Format
terraform fmt -recursive
Validate
terraform validate
Plan
terraform plan
Apply
terraform apply
Show State
terraform state list
Show Resource
terraform state show <RESOURCE>
Import
terraform import <RESOURCE> <ID>
Output
terraform output
45. Recommended Development Workflow

For every infrastructure component:

1. Understand requirement
2. Design architecture
3. Define CIDR / routing
4. Create resource
5. Verify resource
6. Capture IDs
7. Build Terraform module
8. Import resource
9. Run fmt
10. Run validate
11. Run plan
12. Fix drift
13. Apply
14. Verify AWS
15. Document
16. Move to next component
46. Operational Documentation

Each major component should document:

Architecture
Resource IDs
AWS Account
Region
CIDRs
Dependencies
Traffic Flow
Routing
Security Controls
HA Design
Failure Scenarios
Troubleshooting
Terraform Configuration
Terraform State
Operational Commands
47. Cleanup / Decommissioning

Infrastructure must be destroyed in dependency order.

Typical networking dependency chain:

Workloads
   |
VPC Attachments
   |
TGW Routes
   |
TGW
   |
VPN
   |
Cloud WAN
   |
NAT Gateway
   |
EIP
   |
Subnets
   |
Route Tables
   |
VPC
   |
IPAM

Never blindly run:

terraform destroy

against a production-like environment.

First inspect:

terraform plan

and understand resource dependencies.

48. Validation Checklist

Before declaring the architecture complete:

[ ] AWS Organization validated
[ ] OUs validated
[ ] Accounts validated
[ ] Governance validated
[ ] Control Tower validated
[ ] Identity Center validated
[ ] IPAM validated
[ ] CIDR strategy validated
[ ] Core VPC validated
[ ] Subnets validated
[ ] Route tables validated
[ ] NAT validated
[ ] Transit Gateway validated
[ ] TGW route tables validated
[ ] Cloud WAN validated
[ ] VPN validated
[ ] BGP validated
[ ] Azure connectivity validated
[ ] On-Prem connectivity validated
[ ] Network Firewall validated
[ ] VPC Endpoints validated
[ ] PrivateLink validated
[ ] DNS validated
[ ] Cross-account connectivity validated
[ ] ALB/NLB traffic flow validated
[ ] Observability validated
[ ] HA validated
[ ] DR validated
[ ] Terraform imported
[ ] Terraform plan reviewed
[ ] Terraform drift resolved
[ ] Final plan = 0 add / 0 change / 0 destroy
49. Project Status

This repository represents the Terraform implementation and documentation for the Enterprise Master Networking project.

The implementation has covered:

AWS Organization                 ✓
Multi-account architecture       ✓
OUs                              ✓
Governance                       ✓
Control Tower                    ✓
IAM Identity Center              ✓
Network Account                  ✓
VPC/IPAM                         ✓
Transit Gateway                  ✓
Cloud WAN                        ✓
Terraform Modules                ✓
Terraform Reconciliation         ✓
Azure Terraform Foundation      ✓
Hybrid Networking Design        ✓

Additional enterprise networking components are documented as part of the overall architecture and can be implemented incrementally.

50. Important Note

This repository is an enterprise architecture/reference implementation.

AWS resources may not currently exist in the target accounts.

The Terraform source code is retained for:

Architecture reference
Reproduction
Interview preparation
SRE/DevOps learning
Enterprise networking design
Future redeployment
Terraform module reuse

Before deploying into a real environment:

Review all variables.
Review provider versions.
Review IAM permissions.
Review CIDR allocation.
Review routing.
Review security controls.
Review estimated AWS costs.
Review Terraform plan.
Validate all account IDs.
Never use production credentials in source control.
51. Author

Arpit Chouksey

DevOps / SRE Engineer

Areas of focus:

AWS
Azure
Kubernetes
Terraform
Cloud Networking
SRE
Observability
Infrastructure as Code
Cloud Security
Automation
52. Final Principle

The primary objective of this project is not simply to create AWS resources.

The objective is to understand and implement:

Architecture
     +
Networking
     +
Security
     +
Reliability
     +
Observability
     +
Automation
     +
Infrastructure as Code
     +
Troubleshooting

The final architecture should be explainable from:

DNS
  ↓
Ingress
  ↓
VPC
  ↓
Route Table
  ↓
Transit Gateway / Cloud WAN
  ↓
Inspection
  ↓
Hybrid Connectivity
  ↓
Destination

while every infrastructure component remains reproducible and manageable through Terraform.


### One change I strongly recommend before committing

Because this is your **final Git repository**, I would **not put the real Gmail addresses, AWS credentials, tokens, or temporary account-specific secrets into the README**. Your earlier architecture documentation contains account structure and implementation details, but the final README should stay generic and safe for GitHub. The documented design itself separates Security, Log Archive, Network, Shared Services, Production and Non-Production responsibilities. :contentReference[oaicite:1]{index=1}

Also, because your current repository contains `terraform.tfstate` files from the build, make sure those are removed before the final commit as we discussed.

# PersonalProject
Personal DevOps Projects

AWS 3-Tier Architecture with Terraform
📌 Project Overview
This project demonstrates the end-to-end implementation of a highly available, secure, and scalable 3-Tier AWS Architecture. It leverages Terraform (Infrastructure as Code) to automate the deployment of networking, application, and security components.




The architecture follows best practices by segregating the infrastructure into Public (ALB/Internet-facing) and Private (Application/Database) tiers across multiple Availability Zones to ensure fault tolerance.





🏗️ Architecture Design

VPC Foundation: A custom Virtual Private Cloud (10.0.0.0/16) with DNS resolution and hostnames enabled.




Public Tier: Two public subnets hosting an Application Load Balancer (ALB).






Private Tier: Four private subnets (Application and Database tiers) isolated from direct internet access.


Internet Connectivity:


Internet Gateway (IGW) for public subnet ingress/egress.





NAT Gateway (with Elastic IP) to allow private subnets secure outbound traffic for updates.



Security Groups: A layered security model where the App Tier only accepts traffic from the ALB, and the Database Tier only accepts traffic from the App Tier.


🛠️ Tech Stack

Cloud Provider: AWS (VPC, EC2, ALB, NAT Gateway, IAM, Budgets).




Infrastructure as Code: Terraform (>= 1.5.0).



Web Server: NGINX (Application Tier).



CLI Tools: AWS CLI v2.



📁 Repository Structure
Plaintext

.
├── terraform/
│   ├── main.tf            # Root module calling VPC and EC2 modules
│   ├── variables.tf       # Global variable definitions
│   ├── terraform.tfvars   # Variable values (Region, Environment)
│   ├── provider.tf        # AWS Provider configuration
│   ├── backend.tf         # Terraform version and provider constraints
│   ├── outputs.tf         # Root level outputs (VPC ID, ALB DNS)
│   └── modules/
│       └── vpc/           # Reusable VPC, Subnet, and Routing module
│           ├── main.tf
│           ├── variables.tf
│           └── outputs.tf



🚀 Getting Started
1. Cost Safety First
Before deployment, configure a Zero-Spend-Alert in AWS Budgets at a $0.01 threshold to monitor usage in real-time.


2. Prerequisites
AWS CLI configured with programmatic access.


Terraform installed locally.


3. Deployment
Bash

cd terraform

# Initialize and select workspace
terraform init
terraform workspace new dev

# Plan and Apply
terraform plan
terraform apply -auto-approve



🛡️ Security Features

Private Isolation: Application EC2 instances do not have public IPs and are located in private subnets.





Least Privilege: Security groups act as stateful firewalls, allowing only necessary traffic between tiers.



Governance: IAM user programmatic access is used instead of the root account for all operations.



📊 Verification
Audit the deployment using the AWS CLI:

Bash

# Verify running instances
aws ec2 describe-instances --filters Name=instance-state-name,Values=running

# Check Load Balancer status
aws elbv2 describe-load-balancers --query 'LoadBalancers[].LoadBalancerName'




Note: This project was built using a hybrid approach of manual console configuration followed by a Terraform Import to bring existing resources under state management

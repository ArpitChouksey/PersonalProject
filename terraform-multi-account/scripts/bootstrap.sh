#!/bin/bash

set -e

PROJECT="terraform-multi-env"

mkdir -p $PROJECT/modules/{iam-user,terraform-role,vpc,security,alb,launch-template,asg,waf,api-gateway}

mkdir -p $PROJECT/environments/{management,dev,prod}

for env in management dev prod
 do
  touch $PROJECT/environments/$env/main.tf
  touch $PROJECT/environments/$env/provider.tf
  touch $PROJECT/environments/$env/variables.tf
  touch $PROJECT/environments/$env/terraform.tfvars
  touch $PROJECT/environments/$env/backend.tf
 done

 echo "Terraform enterprise structure created successfully"

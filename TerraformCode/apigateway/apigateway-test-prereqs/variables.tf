###############################################################
# Variables
###############################################################

variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-west-2"
}

variable "aws_profile" {
  description = "AWS CLI Profile"
  type        = string
  default     = "default"
}

variable "name_prefix" {
  description = "Prefix applied to every resource this module creates"
  type        = string
  default     = "apigw-simple"
}

variable "manage_apigateway_account_settings" {
  description = "Whether to configure the account-wide CloudWatch Logs role for API Gateway. Set to false if this AWS account already has it configured (e.g. from earlier testing) -- it's a one-time, account-wide setting, not per-deployment."
  type        = bool
  default     = true
}

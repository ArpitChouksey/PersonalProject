variable "environment_tag_value" {
  description = "Value of the environment tag used to target instances (e.g. nprod)"
  type        = string
}

variable "patching_dispatcher_function_arn" {
  description = "ARN of the single dispatcher Lambda handling all 7 tasks"
  type        = string
}

variable "map_max_concurrency" {
  description = "Max concurrent instances processed by the Map state"
  type        = number
}

variable "transient_retry_max_attempts" {
  description = "Max bounded business-level retries for transient patch failures"
  type        = number
}

variable "operation_mode_parameter_name" {
  description = "SSM Parameter Store name holding the operation mode flag (from ssm-policy module) - read live at execution start"
  type        = string
}

variable "take_backup_parameter_name" {
  description = "SSM Parameter Store name holding the takeBackup flag (from ssm-policy module) - read live at execution start"
  type        = string
}

variable "parameter_store_prefix" {
  description = "Prefix path for control-flag parameters in SSM Parameter Store, used to scope the state machine's GetParameter IAM permission"
  type        = string
}

variable "test_schedule_expression" {
  description = "EventBridge schedule expression used during testing phase (e.g. rate(1 hour))"
  type        = string
}

variable "production_schedule_expression" {
  description = "EventBridge schedule expression for the real production cadence (e.g. cron(0 22 ? * SAT *)) - this is the only thing that should trigger a production patch run"
  type        = string
}

variable "enable_test_schedule" {
  description = "Whether the hourly test-schedule EventBridge rule is active. Set false once production cadence is confirmed and the maintenance window schedule alone should drive runs."
  type        = bool
}

variable "tags" {
  description = "Tags applied to all resources created by this module"
  type        = map(string)
}

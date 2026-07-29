output "state_machine_arn" {
  description = "ARN of the patching pipeline state machine"
  value       = aws_sfn_state_machine.patching_pipeline.arn
}

output "state_machine_name" {
  description = "Name of the patching pipeline state machine"
  value       = aws_sfn_state_machine.patching_pipeline.name
}

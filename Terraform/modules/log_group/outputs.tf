#
# In order to allow module consumers to access the outputs, they need to be specified
#
# https://www.terraform.io/docs/language/values/outputs.html
#
output "arn" {
  value       = aws_cloudwatch_log_group.function_log_group.arn
  description = "ARN of the newly created CloudWatch Log Group"
}

output "retention" {
  value       = aws_cloudwatch_log_group.function_log_group.retention_in_days
  description = "Retention period for the Log Group, in days"
}
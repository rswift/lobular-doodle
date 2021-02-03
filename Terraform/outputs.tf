#
# https://www.terraform.io/docs/configuration-0-11/outputs.html
#

output "policy_arn" {
  value       = aws_iam_policy.lambda_policy.arn
  description = "ARN of the newly created IAM Policy for the Lambda function"
}

output "role_arn" {
  value       = aws_iam_role.lambda_role.arn
  description = "ARN of the newly created IAM Role for the Lambda function"
}

output "function_arn" {
  value       = aws_lambda_function.terraform_lambda.arn
  description = "ARN of the newly created Lambda function"
}

output "function_version" {
  value       = aws_lambda_function.terraform_lambda.version
  description = "Version of the newly created Lambda function"
}

output "function_deployment_hash" {
  value       = aws_lambda_function.terraform_lambda.source_code_hash
  description = "Base64-encoded representation of raw SHA-256 sum of the package file"
}

output "function_deployment_size" {
  value       = aws_lambda_function.terraform_lambda.source_code_size
  description = "Size, in bytes, of the package file"
}

output "alias_arn" {
  value       = aws_lambda_alias.terraform_lambda_alias.arn
  description = "ARN of the Lambda alias"
}

output "log_group_retention" {
  value =       module.lambda_log_group.retention
  description = "Retention period for the Log Group, in days"
}
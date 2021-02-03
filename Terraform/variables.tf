#
# Defined in this file (see: https://www.terraform.io/docs/configuration-0-11/variables.html)
#
# Actual values set in terraform.tfvars (see: https://www.terraform.io/docs/configuration-0-11/variables.html#variable-files)
#
# convention: use lower case and underscores
#

variable "function_name" {
  default     = "myPhancyPhunction"
  description = "The name of the Lambda function"
}

variable "function_alias" {
  description = "The alias for the Lambda function"
}

#
# This could be anywhere, showing it as a ../ to demonstrate that it is just a file
# relative to the Terraform root...
#
variable "function_filename" {
  default     = "../Function/lambda_function.py"
  description = "The filename of the Lambda function to deploy - single Python file only"
}

variable "description" {
  default     = "A trivial function for demonstration and testing purposes..."
  description = "Function description"
}

variable "memory_size" {
  default     = "128"
  description = "Function memory in Mb"
}

variable "timeout" {
  default     = "30"
  description = "Function timeout in seconds"
}

variable "publish" {
  default     = "false"
  description = "Boolean indicating if a new version of the function should be published"
}

variable "handler" {
  default     = "lambda_function.lambda_handler"
  description = "Function handler in the format filename.method"
}

variable "runtime" {
  default     = "python3.8"
  description = "Function runtime"
}

variable "logging_level" {
  default     = "INFO"
  description = "Standard logging levels, one of: DEBUG, INFO, WARN, ERROR, CRITICAL"
}

variable "target_account" {
  description = "The AWS account number of the account where the function will be deployed into (via sts:AssumeRole)"
}

#
# Define data items that permit the resolution of the account number and region
#
# https://www.terraform.io/docs/providers/aws/d/caller_identity.html
#
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs#shared-credentials-file
variable "aws_profile" {
  default     = "default"
  description = "The name of the AWS profile to use, as per the shared credentials file"
}

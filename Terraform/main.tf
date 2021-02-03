#
# https://www.terraform.io/docs/configuration/index.html
# https://www.terraform.io/docs/configuration/syntax.html
#

#
# Lambda - Function Defintion 
#
# https://www.terraform.io/docs/providers/aws/r/lambda_function.html
#
resource "aws_lambda_function" "terraform_lambda" {
  function_name    = var.function_name
  description      = var.description
  filename         = data.archive_file.lambda_deployment_package.output_path
  role             = aws_iam_role.lambda_role.arn
  handler          = var.handler
  runtime          = var.runtime
  memory_size      = var.memory_size
  timeout          = var.timeout
  publish          = var.publish
  source_code_hash = filebase64sha256(data.archive_file.lambda_deployment_package.output_path)

  environment {
    variables = {
      LOGGING_LEVEL = var.logging_level
    }
  }

  tracing_config {
    mode = "Active"
  }

  #
  # sometimes it is necessary to force Terraform to wait for a resource, it gets it right
  # most of the time (it would in this case, due to the 'role' reference above), but occasionally 
  # it needs to be told...
  #
  depends_on = [aws_iam_role.lambda_role, module.lambda_log_group]
}

#
# Bit of a hack to create the deployment zip, note that the AWS Lambda service will unzip
# the file with the permissions as set, the file itself needs to be readable by the Lambda
# service at run time: chmod 644
#
data "archive_file" "lambda_deployment_package" {
  type        = "zip"
  source_file = var.function_filename
  output_path = replace(var.function_filename, ".py", ".zip")
}

#
# Define an alias to allow the migration of one function version to another, and in readiness
# for provisioned concurrency (but really, just to demonstrate inputs from one resource to another)
#
resource "aws_lambda_alias" "terraform_lambda_alias" {
  name             = var.function_alias
  description      = "An alias that maps to version ${aws_lambda_function.terraform_lambda.version} of ${var.function_name}"
  function_name    = aws_lambda_function.terraform_lambda.arn
  function_version = aws_lambda_function.terraform_lambda.version
}

#
# pre-create the log group so that the retention period can be set
# and demonstrate the use of modules to enforce requirements such
# as tags (billing owner on this case) etc.
#
module "lambda_log_group" {
  source =  "./modules/log_group"

  #
  # specify those variables that are required
  #
  name          = var.function_name
  billing_owner = "Stephen"

  #
  # this variable isn't set because it doesn't need to be, but
  # it could override the module default
  #
##  retention_in_days = 5
}

#
# This configuration specifies the IAM Role & Policy for the Lambda function
#
# IAM Role
#
resource "aws_iam_role" "lambda_role" {
  name                  = "${var.function_name}_lambda_execution_role"
  description           = "Role to enable the Lambda function to, well, function"
  assume_role_policy    = data.aws_iam_policy_document.lambda_assume_role_policy_document.json
  force_detach_policies = true
}

#
# IAM Policy for the Lambda requirement
#
data "aws_iam_policy_document" "lambda_policy_document" {
  statement {
    sid       = "CloudWatchCreateLogGroupForLambda"
    actions   = ["logs:CreateLogGroup"]
    resources = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"]
  }

  statement {
    sid       = "BasicCloudWatchLogStreamForLambda"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.function_name}:*"]
  }
}

resource "aws_iam_policy" "lambda_policy" {
  name        = "${var.function_name}_lambda_policy"
  description = "Enables CloudWatch log group & log stream creation and the ability to write log events"
  path        = "/"
  policy      = data.aws_iam_policy_document.lambda_policy_document.json
}

#
# IAM Policy for the Lambda role, sts:AssumeRole requirement
#
data "aws_iam_policy_document" "lambda_assume_role_policy_document" {
  statement {
    sid     = "AllowLambdaAssumeRole"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

#
# Attach the policy to the role
#
resource "aws_iam_role_policy_attachment" "lambda_role_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

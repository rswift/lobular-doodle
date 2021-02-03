#
# a very simple example of a module, in this case to add
#
resource "aws_cloudwatch_log_group" "function_log_group" {
  name              = "/aws/lambda/${var.name}"
  retention_in_days = var.retention_in_days
  tags = {
    "Billing" = var.billing_owner
  }
}

variable service {
  type = string
}

variable handler {
  type = string
}

variable package {
  type = string
}

variable environment {
  type = map(string)
}

variable "memory" {
  type = number
}

variable "timeout" {
  type = number
}

variable "runtime" {
  type = string
}

variable "network" {
  type = object({
    subnets         = list(string)
    security_groups = list(string)
  })
}

variable "tags" {
  type = map(string)
}

variable "reserved_concurrent_executions" {
    type    = number
    default = -1
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.service}"
  retention_in_days = 7
  tags              = var.tags
}

resource "aws_lambda_function" "func_extract" {
  filename         = var.package
  function_name    = var.service
  source_code_hash = filebase64sha256(var.package)
  role             = aws_iam_role.role.arn
  handler          = var.handler
  runtime          = var.runtime
  memory_size      = var.memory
  timeout          = var.timeout
  reserved_concurrent_executions = var.reserved_concurrent_executions
  environment {
    variables = var.environment
  }
  tags = var.tags

  vpc_config {
    subnet_ids         = var.network.subnets
    security_group_ids = var.network.security_groups
  }

  depends_on = [aws_cloudwatch_log_group.lambda]
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.func_extract.function_name
  principal     = "events.amazonaws.com"

}

resource "aws_cloudwatch_metric_alarm" "errors-alarm" {
  alarm_name          = "${aws_lambda_function.func_extract.function_name}-error-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "AWS/Lambda Errors - ${aws_lambda_function.func_extract.function_name}"
  alarm_actions = ["arn:aws:sns:us-east-1:280917728158:squad-data-alarm"]

  dimensions = {
    FunctionName = aws_lambda_function.func_extract.function_name
  }

  tags = var.tags
}

output "arn" {
  value = aws_lambda_function.func_extract.arn
}

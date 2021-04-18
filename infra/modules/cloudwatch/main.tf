variable "name" {
  type = string
}

variable "cron" {
  type = string
}

variable "arn_lambda" {
  type = string
}

variable "tags" {
  type = map(string)
}

resource "aws_cloudwatch_event_rule" "event_lambda" {
  name                =  "${var.name}-${lookup(var.tags, "Environment", "null")}"
  schedule_expression =  var.cron
  tags = var.tags
}

resource "aws_cloudwatch_event_target" "example" {
  arn  = var.arn_lambda
  rule = aws_cloudwatch_event_rule.event_lambda.id

}

output "arn_event_rule" {
  value = aws_cloudwatch_event_rule.event_lambda.arn
}
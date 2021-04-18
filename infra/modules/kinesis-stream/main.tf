variable "name" {
    type = string
}

variable "tags" {
  type = map(string)
}

variable "retention_period" {
  
}

resource "aws_kinesis_stream" "data_stream" {
  name             = "${var.name}_ml_platform"
  shard_count      = 1
  retention_period = var.retention_period

  shard_level_metrics = [
    "IncomingBytes",
    "OutgoingBytes",
  ]

  tags = var.tags
}

output "data_stream_arn" {
  value = aws_kinesis_stream.data_stream.arn
}

output "data_stream_name" {
  value = aws_kinesis_stream.data_stream.name
}
variable "bucket" {
  type = object({
    arn  = string
    name = string
  })

}
variable "database" {
  type = string
}
variable "table" {
  type = string
}

variable "name" {
  type = string
}

variable "event" {
  type = object({
    name    = string
    scope   = string
  })
}

variable "tags" {
  type = map(string)
}

variable "enabled" {
  type = bool
}

variable "kinesis_stream_arn" {
  type = string
}

resource "aws_kinesis_firehose_delivery_stream" "kinesis_firehose_stream_transform" {
  name        = var.name
  destination = "extended_s3"
  tags        = var.tags

  kinesis_source_configuration {
    kinesis_stream_arn = var.kinesis_stream_arn
    role_arn = aws_iam_role.firehose_role.arn
  }
  
  extended_s3_configuration {
    role_arn        = aws_iam_role.firehose_role.arn
    bucket_arn      = var.bucket.arn
    buffer_size     = 128
    buffer_interval = 60


    data_format_conversion_configuration {
      input_format_configuration {
        deserializer {
          hive_json_ser_de {}
        }
      }

      output_format_configuration {
        serializer {
          parquet_ser_de {}
        }
      }

      schema_configuration {
        database_name = var.database
        table_name    = var.table
        role_arn      = aws_iam_role.firehose_role.arn
      }
    }
    prefix              = "events/${var.event.scope}/${var.event.name}/transform/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hl_hour=!{timestamp:HH}/"
    error_output_prefix = "error/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/!{firehose:error-output-type}"
  }
}

resource "aws_iam_role" "firehose_role" {

  name               = "event-${var.event.scope}-${var.event.name}-firehose-role"
  tags               = var.tags
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "firehose.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "fire_hose_policy" {
  name        = "event-${var.event.scope}-${var.event.name}-firehose-policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "glue:GetTableVersions"
      ],
      "Resource": "*"
    },  
    {
      "Action": [
          "s3:AbortMultipartUpload",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:PutObject",
          "glue:GetTable",
          "glue:GetTableVersion",
          "glue:GetTableVersions",
          "kinesis:*"
      ],
      "Effect": "Allow",
      "Resource": [
          "arn:aws:s3:::${var.bucket.name}",
          "arn:aws:s3:::${var.bucket.name}/*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "role_policy_fire_hose_attach" {
  role       = aws_iam_role.firehose_role.name
  policy_arn = aws_iam_policy.fire_hose_policy.arn
}

// FailedConversion.Records Alarm - 1 in 30 seconds.
resource "aws_cloudwatch_metric_alarm" "failed-conversion-alarm" {

  alarm_name          = "whale-event-${var.event.scope}-${var.event.name}-failed-conversion-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "FailedConversion.Records"
  namespace           = "AWS/Firehose"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "AWS/Lambda Invocations - whale-event-${var.event.scope}-${var.event.name}"
  alarm_actions = [
  "arn:aws:sns:us-east-1:280917728158:squad-data-alarm"]

  dimensions = {
    DeliveryStreamName = "event-${var.event.scope}-${var.event.name}"
  }

  tags = var.tags
}

output "name" {
  value = aws_kinesis_firehose_delivery_stream.kinesis_firehose_stream_transform.name
}
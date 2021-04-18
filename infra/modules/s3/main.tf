variable "tags" {
  type = map(string)
}

variable "name" {
  type = string
}

resource "aws_s3_bucket" "events_bucket" {
  bucket = "${var.name}-ml-platform-event"
  acl    = "private"

  tags = var.tags
}

output "arn" {
  value = aws_s3_bucket.events_bucket.arn
}

output "name" {
  value = aws_s3_bucket.events_bucket.bucket
}
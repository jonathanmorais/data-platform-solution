data "aws_iam_policy_document" "glue_role_policy" {
	statement {
		actions = [
		"sts:AssumeRole"]

		principals {
			type = "Service"
			identifiers = ["glue.amazonaws.com","events.amazonaws.com","lambda.amazonaws.com"]
		}
	}
}

resource "aws_iam_policy" "glue_policy" {
  name        = "glue_policy-${var.event.scope}_${var.event.name}"
  description = "A test policy"

  policy = <<EOF
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Action": "athena:*",
			"Effect": "Allow",
			"Resource": "*"
		},
		{
			"Action": "s3:*",
			"Effect": "Allow",
			"Resource": "*"
		},
		{
			"Action": "logs:PutLogEvents",
			"Effect": "Allow",
			"Resource": "*"
		}

	]
}
EOF
  tags = var.tags

}

resource "aws_iam_role_policy_attachment" "glue_attach_role_policy" {
  role       = aws_iam_role.glue_role.name
  policy_arn = aws_iam_policy.glue_policy.arn
}

resource "aws_iam_role" "glue_role" {
  name = "glue_role-${var.event.scope}_${var.event.name}"

  assume_role_policy = data.aws_iam_policy_document.glue_role_policy.json

    lifecycle {
        prevent_destroy = false
    }
  
  tags = var.tags

}
data "aws_iam_policy_document" "lambda_role_policy" {
	statement {
		actions = [
		"sts:AssumeRole"]

		principals {
			type = "Service"
			identifiers = [
				"apigateway.amazonaws.com",
				"events.amazonaws.com",
				"lambda.amazonaws.com",
				"ecs-tasks.amazonaws.com"]
		}
	}
}

resource "aws_iam_role" "role" {
	name = "lambdaExecRole_${var.service}"

	assume_role_policy = data.aws_iam_policy_document.lambda_role_policy.json

	lifecycle {
		prevent_destroy = false
	}

	tags = var.tags

}

resource "aws_iam_role_policy" "lambda_policy" {
	name = "lambdaExecRolePolicy_${var.service}"
	role = aws_iam_role.role.id

	policy = <<EOF
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Action": [
				"ec2:AttachNetworkInterface",
				"ec2:CreateNetworkInterface",
				"ec2:DeleteNetworkInterface",
				"ec2:DescribeInstances",
				"ec2:DescribeNetworkInterfaces",
				"ec2:DetachNetworkInterface",
				"ec2:ModifyNetworkInterfaceAttribute",
				"ec2:ResetNetworkInterfaceAttribute"
			],
			"Effect": "Allow",
			"Resource": "*"
		},
		{
			"Action": [
				"logs:CreateLogGroup",
				"logs:CreateLogStream",
				"logs:PutLogEvents",
				"logs:DescribeLogStreams"
			],
			"Effect": "Allow",
			"Resource": "*"
		},
		{
			"Action": "sns:*",
			"Effect": "Allow",
			"Resource": "*"
		},
		{
			"Action": "glue:*",
			"Effect": "Allow",
			"Resource": "*"
		},
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
			"Action": "kms:*",
			"Effect": "Allow",
			"Resource": "*"
		},
		{
			"Action": "kinesis:*",
			"Effect": "Allow",
			"Resource": "*"
		}
	]
}
EOF
}

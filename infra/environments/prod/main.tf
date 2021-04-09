provider "aws" {
  region = "us-east-1"
  shared_credentials_file = "~/.aws/credentials"
  profile                 = "personal"
}

terraform {
  backend "s3" {
    bucket         = "personal-us-east-1"
    key            = "terraform/ml-platform/terraform.tfstate"
    region         = "us-east-1"
  }
}

locals {
  tags = {
    Project     = "ml-platform"
    Environment = "prod"
  }
}

module "cloudwatch-trigger" {
  source = "../../modules/cloudwatch"
  name   = "ml-lambda-trigger"
  cron   = "rate(5 minutes)"
  arn_lambda = module.lambda-extraction.arn
  tags   = local.tags
}

module "lambda-extraction" {
  source                         = "../../modules/lambda"
  service                        = "lambda-extraction" ## concat with env
  reserved_concurrent_executions = 10
  network = {
    subnets         = ["subnet-01f5febe2b73ce0cf"],
    security_groups = ["sg-0066899a04deddb7e"]
  }
  tags = local.tags
  
  package = "../../../lambda-extract.zip"

  environment = {}

  memory  = 128
  timeout = 60
  runtime = "python3.6"
  handler = "lambda_extract.lambda_handler"
}

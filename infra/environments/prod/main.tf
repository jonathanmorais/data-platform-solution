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

  environment = {
    "URL"              = "https://api.punkapi.com/v2/beers/random"
    "DELIVERY_STREAM"  = module.kinesis-fire-all.name
  }
 
  package = "../../../lambda-extract.zip"

  memory  = 128
  timeout = 60
  runtime = "python3.6"
  handler = "lambda_extract.lambda_handler"
}

module "bucket-events" {
    source  = "../../modules/s3"
    name    = "ml-platform"
    tags    = local.tags
}

module "kinesis-fire-all" {
    source  = "../../modules/kinesis-fire"
    name    = "events-punkapi"

    enabled = false

    event = {
        scope   = "ml-platform"
        name    = "punkapi"    
    }
    bucket = {
        arn  = module.bucket-events.arn
        name = module.bucket-events.name  
    }

    database = module.glue_catalog.database_name
    table    = module.glue_catalog.table_name

    tags    = local.tags
}

module "glue_catalog" {
    source  = "../../modules/glue"
    event = {
        scope   = "ml-platform"
        name    = "punkapi"    
    }

    tags = local.tags
}
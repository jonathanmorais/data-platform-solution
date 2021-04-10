provider "aws" {
  region = "us-east-1"
  shared_credentials_file = "~/.aws/credentials"
  profile                 = "default"
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
    "DELIVERY_STREAM"  = module.kinesis-fire-transform.name
  }
 
  package = "../../../client.zip"

  memory  = 128
  timeout = 60
  runtime = "python3.6"
  handler = "client.lambda_handler"
}

module "bucket-events-raw" {
    source  = "../../modules/s3"
    name    = "raw"
    tags    = local.tags
}

module "bucket-events-cleaned" {
    source  = "../../modules/s3"
    name    = "cleaned"
    tags    = local.tags
}

module "kinesis-data-stream" {
  source = "../../modules/kinesis-stream"
  name = "stream"
  retention_period = 48
  tags    = local.tags
}

module "kinesis-fire-all" {
    source  = "../../modules/kinesis-fire-all"
    name    = "events-all"

    enabled = false

    event = {
        scope   = "ml-platform"
        name    = "punkapi"    
    }
    bucket = {
        arn  = module.bucket-events-raw.arn
        name = module.bucket-events-raw.name  
    }

    kinesis_stream_arn = module.kinesis-data-stream.data_stream_arn   

    tags    = local.tags
}

module "kinesis-fire-transform" {
    source  = "../../modules/kinesis-fire-transform"
    name    = "events-transform"

    enabled = false

    event = {
        scope   = "ml-platform"
        name    = "punkapi"    
    }
    bucket = {
        arn  = module.bucket-events-cleaned.arn
        name = module.bucket-events-cleaned.name  
    }

    kinesis_stream_arn = module.kinesis-data-stream.data_stream_arn

    database = module.glue_catalog.database_name
    table    = module.glue_catalog.table_name

    tags    = local.tags
}

module "glue_catalog" {
    source  = "../../modules/glue"
    bucket = module.bucket-events-cleaned.name
    event = {
        scope   = "ml-platform"
        name    = "punkapi"    
    }

    tags = local.tags
}
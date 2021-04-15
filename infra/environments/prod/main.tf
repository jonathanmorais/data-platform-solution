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

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "vpc-01"

  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_ipv6 = false

  enable_nat_gateway = true
  single_nat_gateway = true

  enable_s3_endpoint       = false
  enable_dynamodb_endpoint = true

  public_subnet_tags = {
    Name = "public-subnet"
  }

  tags = local.tags

  vpc_tags = local.tags

}

module "sg" {
  source = "terraform-aws-modules/security-group/aws//modules/http-80"

  name        = "external-traffic"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
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
    subnets         = [module.vpc.private_subnets[0], module.vpc.private_subnets[1]],
    security_groups = [module.sg.this_security_group_id]
  }
  tags = local.tags

  environment = {
    "URL"          = "https://api.punkapi.com/v2/beers/random"
    "STREAM_NAME"  = module.kinesis-data-stream.data_stream_name
  }
 
  package = "../../../client.zip"

  memory  = 128
  timeout = 60
  runtime = "python3.6"
  handler = "client.lambda_handler"
}

module "lambda-processor" {
  source                         = "../../modules/lambda"
  service                        = "lambda-processor" ## concat with env
  reserved_concurrent_executions = 10
  network = {
    subnets         = [module.vpc.private_subnets[0], module.vpc.private_subnets[1]],
    security_groups = [module.sg.this_security_group_id]
  }
  tags = local.tags

  environment = {
    "STREAM_NAME"  = module.kinesis-data-stream.data_stream_name
  }
 
  package = "../../../client_processor.zip"

  memory  = 128
  timeout = 60
  runtime = "python3.6"
  handler = "client_processor.lambda_handler"
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
    source  = "../../modules/kinesis-firehose"
    name    = "events_all"

    enabled = false

    processor = module.lambda-processor.arn

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
    source  = "../../modules/kinesis-firehose"
    name    = "events_transform"

    enabled = true

    processor = module.lambda-processor.arn
    event = {
        scope   = "ml-platform"
        name    = "punkapi"    
    }
    bucket = {
        arn  = module.bucket-events-cleaned.arn
        name = module.bucket-events-cleaned.name  
    }

    kinesis_stream_arn = module.kinesis-data-stream.data_stream_arn

    tags    = local.tags
}

module "glue_catalog" {
    source  = "../../modules/glue"
    bucket = module.bucket-events-cleaned.name
    cron = "0 0/1 * * ? *"
    event = {
        scope   = "ml-platform"
        name    = "punkapi"    
    }

    tags = local.tags
}
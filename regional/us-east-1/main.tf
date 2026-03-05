terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# DynamoDB (regional)
module "dynamodb" {
  source = "../modules/dynamodb"

  table_name  = "GreetingLogs-${var.region}"
  environment = "prod"
}

# ECS Fargate (regional)
module "ecs" {
  source = "../modules/ecs_fargate"
  name          = "unleashlive"
  region        = var.region
  sns_topic_arn = data.terraform_remote_state.global.outputs.sns_topic_arn
  email         = var.email
  repo          = var.repo
}

# Lambda Greeter (regional)
module "lambda_greet" {
  source = "../modules/lambda_greet"
  name                = "unleashlive"
  region              = var.region
  dynamodb_table_name = module.dynamodb.table_name
  dynamodb_table_arn  = module.dynamodb.table_arn
  sns_topic_arn       = data.terraform_remote_state.global.outputs.sns_topic_arn

  email = var.email
  repo  = var.repo
}

# Lambda Dispatcher (regional)
module "lambda_dispatch" {
  source = "../modules/lambda_dispatch"
  name                    = "unleashlive"
  region                  = var.region
  cluster_arn             = module.ecs.cluster_arn
  task_definition_arn     = module.ecs.task_definition_arn
  task_execution_role_arn = module.ecs.task_execution_role_arn
  subnet_id               = module.ecs.public_subnet_id

  sns_topic_arn = data.terraform_remote_state.global.outputs.sns_topic_arn
  email         = var.email
  repo          = var.repo
}

# API Gateway (regional)
module "api_gateway" {
  source = "../modules/api_gateway"

  name = "unleashlive"

  # Cognito (global us-east-1)
  user_pool_id        = data.terraform_remote_state.global.outputs.user_pool_id
  user_pool_client_id = data.terraform_remote_state.global.outputs.user_pool_client_id

  # Lambda integrations (regional)
  lambda_greet_arn    = module.lambda_greet.lambda_arn
  lambda_dispatch_arn = module.lambda_dispatch.lambda_arn
  region              = var.region
}

# Outputs
output "api_endpoint" {
  value = module.api_gateway.api_endpoint
}

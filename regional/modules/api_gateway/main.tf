# REST API
resource "aws_api_gateway_rest_api" "this" {
  name = "${var.name}-rest-api"
}

# Root "/"
data "aws_api_gateway_resource" "root" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  path        = "/"
}

# Cognito Authorizer
data "aws_caller_identity" "current" {}

resource "aws_api_gateway_authorizer" "cognito" {
  name        = "cognito-authorizer"
  rest_api_id = aws_api_gateway_rest_api.this.id
  type        = "COGNITO_USER_POOLS"

  identity_source = "method.request.header.Authorization"

  provider_arns = [
    "arn:aws:cognito-idp:us-east-1:${data.aws_caller_identity.current.account_id}:userpool/${var.user_pool_id}"
  ]

  authorizer_result_ttl_in_seconds = 300
}

# /greet  (GET)
resource "aws_api_gateway_resource" "greet" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = data.aws_api_gateway_resource.root.id
  path_part   = "greet"
}

resource "aws_api_gateway_method" "greet_get" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.greet.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_integration" "greet_integration" {
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.greet.id
  http_method             = aws_api_gateway_method.greet_get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${var.lambda_greet_arn}/invocations"
}

# /dispatch  (GET)
resource "aws_api_gateway_resource" "dispatch" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = data.aws_api_gateway_resource.root.id
  path_part   = "dispatch"
}

resource "aws_api_gateway_method" "dispatch_get" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.dispatch.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_integration" "dispatch_integration" {
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.dispatch.id
  http_method             = aws_api_gateway_method.dispatch_get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${var.lambda_dispatch_arn}/invocations"
}

# Lambda Permissions
resource "aws_lambda_permission" "greet_permission" {
  statement_id  = "AllowAPIGatewayInvokeGreet"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_greet_arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.this.execution_arn}/*/*"
}

resource "aws_lambda_permission" "dispatch_permission" {
  statement_id  = "AllowAPIGatewayInvokeDispatch"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_dispatch_arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.this.execution_arn}/*/*"
}

# Deployment + Stage
resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id

  triggers = {
    redeploy = sha1(jsonencode({
      greet_method          = aws_api_gateway_method.greet_get.id
      greet_integration     = aws_api_gateway_integration.greet_integration.id
      dispatch_method       = aws_api_gateway_method.dispatch_get.id
      dispatch_integration  = aws_api_gateway_integration.dispatch_integration.id
    }))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "prod" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  deployment_id = aws_api_gateway_deployment.this.id
  stage_name    = "prod"
}

# Output
output "invoke_url" {
  value = "https://${aws_api_gateway_rest_api.this.id}.execute-api.${var.region}.amazonaws.com/prod"
}

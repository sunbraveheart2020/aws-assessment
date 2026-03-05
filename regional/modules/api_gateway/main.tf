resource "aws_apigatewayv2_api" "this" {
  name          = "${var.name}-api"
  protocol_type = "HTTP"
}

# Cognito JWT Authorizer (points to us-east-1 User Pool)
resource "aws_apigatewayv2_authorizer" "cognito" {
  api_id           = aws_apigatewayv2_api.this.id
  name             = "cognito-authorizer"
  authorizer_type  = "JWT"

  identity_sources = ["$request.header.Authorization"]

  jwt_configuration {
    audience = [var.user_pool_client_id]
    issuer   = "https://cognito-idp.us-east-1.amazonaws.com/${var.user_pool_id}"
  }
}

# Integrations for Lambda functions
resource "aws_apigatewayv2_integration" "greet" {
  api_id                 = aws_apigatewayv2_api.this.id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.lambda_greet_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "dispatch" {
  api_id                 = aws_apigatewayv2_api.this.id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.lambda_dispatch_arn
  payload_format_version = "2.0"
}

# Routes
resource "aws_apigatewayv2_route" "greet" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "GET /greet"

  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id

  target = "integrations/${aws_apigatewayv2_integration.greet.id}"
}

resource "aws_apigatewayv2_route" "dispatch" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "POST /dispatch"

  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id

  target = "integrations/${aws_apigatewayv2_integration.dispatch.id}"
}


# Stage
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = "$default"
  auto_deploy = true
}

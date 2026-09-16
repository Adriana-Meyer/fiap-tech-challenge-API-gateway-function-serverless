resource "aws_apigatewayv2_api" "main" {
  name          = "${var.project_name}-api-gateway"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = "$default"
  auto_deploy = true
}

# POST /auth/token -> Lambda (validates CPF, delegates to the app's
# login endpoint, relays the JWT back)
resource "aws_apigatewayv2_integration" "auth_lambda" {
  api_id                 = aws_apigatewayv2_api.main.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.auth.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "auth_token" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "POST /auth/token"
  target    = "integrations/${aws_apigatewayv2_integration.auth_lambda.id}"
}

# Every other existing route (/api/v1/**, /swagger-ui/**,
# /actuator/health/**) -> HTTP proxy straight to the app's LoadBalancer,
# unchanged. The app's own Spring Security keeps doing JWT validation
# and role-based authorization exactly as it does today.
resource "aws_apigatewayv2_integration" "app_proxy" {
  api_id                 = aws_apigatewayv2_api.main.id
  integration_type       = "HTTP_PROXY"
  integration_method     = "ANY"
  integration_uri        = "http://${var.app_backend_host}/{proxy}"
  payload_format_version = "1.0"
}

resource "aws_apigatewayv2_route" "app_proxy" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.app_proxy.id}"
}

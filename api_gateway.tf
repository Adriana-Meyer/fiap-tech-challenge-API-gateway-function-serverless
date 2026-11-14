resource "aws_apigatewayv2_api" "main" {
  name          = "${var.project_name}-api-gateway"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = "$default"
  auto_deploy = true
}

# POST /auth/token -> Lambda (validates CPF, delegates to the OS service's
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

# Phase 4 split the system in four services, each behind its own load balancer.
# The gateway stays the single entry point and sends each path prefix to the
# service that owns it. Anything not listed here belongs to the OS service.
#
# Every service keeps validating the JWT and the roles itself (they all share
# the OS service's signing secret); the gateway only routes.
locals {
  service_prefixes = {
    inventory = ["/api/v1/supplies", "/api/v1/stock-reservations"]
    billing   = ["/api/v1/budgets", "/api/v1/payments"]
    execution = ["/api/v1/executions"]
  }

  # prefix => the service that owns it
  prefix_owner = merge([
    for service, prefixes in local.service_prefixes : { for prefix in prefixes : prefix => service }
  ]...)
}

# Two routes per prefix, because "/prefix/{proxy+}" does not match "/prefix"
# itself (a greedy variable needs at least one more segment), and the list
# and create calls are exactly that: GET/POST /api/v1/supplies.
#
# API Gateway picks the most specific route that matches, so these win over
# the catch-all below.
resource "aws_apigatewayv2_integration" "prefix_exact" {
  for_each = local.prefix_owner

  api_id                 = aws_apigatewayv2_api.main.id
  integration_type       = "HTTP_PROXY"
  integration_method     = "ANY"
  integration_uri        = "http://${var.service_hosts[each.value]}${each.key}"
  payload_format_version = "1.0"
}

resource "aws_apigatewayv2_route" "prefix_exact" {
  for_each = local.prefix_owner

  api_id    = aws_apigatewayv2_api.main.id
  route_key = "ANY ${each.key}"
  target    = "integrations/${aws_apigatewayv2_integration.prefix_exact[each.key].id}"
}

resource "aws_apigatewayv2_integration" "prefix_children" {
  for_each = local.prefix_owner

  api_id                 = aws_apigatewayv2_api.main.id
  integration_type       = "HTTP_PROXY"
  integration_method     = "ANY"
  integration_uri        = "http://${var.service_hosts[each.value]}${each.key}/{proxy}"
  payload_format_version = "1.0"
}

resource "aws_apigatewayv2_route" "prefix_children" {
  for_each = local.prefix_owner

  api_id    = aws_apigatewayv2_api.main.id
  route_key = "ANY ${each.key}/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.prefix_children[each.key].id}"
}

# Everything else (/api/v1/service-orders/**, customers, vehicles, services,
# tracking, webhooks, swagger, actuator) -> the OS service, unchanged.
resource "aws_apigatewayv2_integration" "os_proxy" {
  api_id                 = aws_apigatewayv2_api.main.id
  integration_type       = "HTTP_PROXY"
  integration_method     = "ANY"
  integration_uri        = "http://${var.service_hosts.os}/{proxy}"
  payload_format_version = "1.0"
}

resource "aws_apigatewayv2_route" "os_proxy" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.os_proxy.id}"
}

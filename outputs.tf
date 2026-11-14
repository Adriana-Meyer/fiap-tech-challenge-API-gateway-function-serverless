output "api_gateway_url" {
  value = aws_apigatewayv2_stage.default.invoke_url
}

output "auth_token_endpoint" {
  value = "${aws_apigatewayv2_stage.default.invoke_url}auth/token"
}

output "routes" {
  description = "Where each route sends the request. For checking the routing table after an apply."
  value = merge(
    { "POST /auth/token" = "lambda ${aws_lambda_function.auth.function_name}" },
    { for prefix, route in aws_apigatewayv2_route.prefix_exact : route.route_key => aws_apigatewayv2_integration.prefix_exact[prefix].integration_uri },
    { for prefix, route in aws_apigatewayv2_route.prefix_children : route.route_key => aws_apigatewayv2_integration.prefix_children[prefix].integration_uri },
    { "ANY /{proxy+}" = aws_apigatewayv2_integration.os_proxy.integration_uri },
  )
}

output "api_gateway_url" {
  value = aws_apigatewayv2_stage.default.invoke_url
}

output "auth_token_endpoint" {
  value = "${aws_apigatewayv2_stage.default.invoke_url}auth/token"
}

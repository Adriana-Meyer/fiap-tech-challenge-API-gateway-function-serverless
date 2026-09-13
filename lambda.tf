# AWS Academy Learner Lab only allows pre-created IAM roles — LabRole
# covers Lambda (per the Lab's own service documentation).
data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

# Built by `mvn -f lambda/auth package` before `terraform apply` (see
# CI/CD workflows) — Terraform doesn't run Maven itself, it just
# references the shaded jar the build step produces.
resource "aws_lambda_function" "auth" {
  function_name    = "${var.project_name}-cpf-auth"
  role             = data.aws_iam_role.lab_role.arn
  handler          = "com.fiap.workshop.lambda.auth.AuthHandler::handleRequest"
  runtime          = "java17"
  filename         = "${path.module}/lambda/auth/target/auth-cpf-lambda.jar"
  source_code_hash = filebase64sha256("${path.module}/lambda/auth/target/auth-cpf-lambda.jar")

  # Java benefits from more memory (Lambda allocates CPU proportionally),
  # which shortens JVM cold start; timeout covers cold start + the HTTP
  # call to the app's login endpoint.
  memory_size = 512
  timeout     = 15

  environment {
    variables = {
      APP_LOGIN_URL = "http://${var.app_backend_host}/api/v1/auth/login"
    }
  }
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auth.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*/auth/token"
}

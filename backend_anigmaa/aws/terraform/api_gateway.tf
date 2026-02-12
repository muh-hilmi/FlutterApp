# API Gateway
resource "aws_apigatewayv2_api" "anigmaa_api" {
  name          = "${var.project_name}-backend-api"
  protocol_type = "HTTP"
  cors_configuration {
    allow_origins = split(",", var.allowed_origins)
    allow_methods = ["*"]
    allow_headers = ["*"]
    expose_headers = ["*"]
    max_age       = 300
  }

  tags = {
    Name = "${var.project_name}-api"
  }
}

# API Gateway Stage
resource "aws_apigatewayv2_stage" "anigmaa_api_stage" {
  api_id      = aws_apigatewayv2_api.anigmaa_api.id
  name        = var.environment
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_logs.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      resourcePath   = "$context.resourcePath"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
      integrationLatency = "$context.integration.latency"
      error          = "$context.error.message"
      errorType      = "$context.error.messageString"
    })
  }

  tags = {
    Name = "${var.project_name}-api-stage"
  }

  depends_on = [aws_cloudwatch_log_group.api_gateway_logs]
}

# CloudWatch Log Group for API Gateway
resource "aws_cloudwatch_log_group" "api_gateway_logs" {
  name              = "/aws/apigateway/${var.project_name}"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-api-logs"
  }
}

# API Gateway Integration with Lambda
resource "aws_apigatewayv2_integration" "anigmaa_backend_integration" {
  api_id           = aws_apigatewayv2_api.anigmaa_api.id
  integration_type = "AWS_PROXY"

  integration_method = "POST"
  integration_uri    = aws_lambda_function.anigmaa_backend.invoke_arn

  payload_format_version = "2.0"

  depends_on = [aws_lambda_function.anigmaa_backend]
}

# API Gateway Route - Catch all routes
resource "aws_apigatewayv2_route" "anigmaa_backend_route" {
  api_id    = aws_apigatewayv2_api.anigmaa_api.id
  route_key = "$default"

  target = "integrations/${aws_apigatewayv2_integration.anigmaa_backend_integration.id}"

  depends_on = [aws_apigatewayv2_integration.anigmaa_backend_integration]
}

# Lambda Permission for API Gateway
resource "aws_lambda_permission" "api_gateway_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.anigmaa_backend.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.anigmaa_api.execution_arn}/*/*"

  depends_on = [aws_lambda_function.anigmaa_backend]
}

# Custom Domain Name (Optional - only if domain_name is provided)
resource "aws_apigatewayv2_domain_name" "anigmaa_custom_domain" {
  count       = var.domain_name != "" ? 1 : 0
  domain_name = var.domain_name

  domain_name_configuration {
    certificate_arn        = var.certificate_arn
    endpoint_type          = "REGIONAL"
    target_domain_name     = aws_apigatewayv2_api.anigmaa_api.api_endpoint
    security_policy        = "TLS_1_2"
  }

  tags = {
    Name = "${var.project_name}-custom-domain"
  }
}

# API Gateway Domain Mapping (Optional)
resource "aws_apigatewayv2_api_mapping" "anigmaa_api_mapping" {
  count       = var.domain_name != "" ? 1 : 0
  api_id      = aws_apigatewayv2_api.anigmaa_api.id
  domain_name = aws_apigatewayv2_domain_name.anigmaa_custom_domain[0].domain_name
  stage       = aws_apigatewayv2_stage.anigmaa_api_stage.name

  depends_on = [aws_apigatewayv2_domain_name.anigmaa_custom_domain]
}

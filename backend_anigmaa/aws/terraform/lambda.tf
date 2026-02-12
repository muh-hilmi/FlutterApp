# Lambda Layer untuk dependencies
# Note: Lambda layer is optional - commented out if not using external dependencies
# resource "aws_lambda_layer_version" "anigmaa_dependencies" {
#   filename   = "lambda-layer.zip"
#   layer_name = "${var.project_name}-dependencies"
#
#   source_code_hash = filebase64sha256("lambda-layer.zip")
#
#   compatible_runtimes = ["go1.x", "provided.al2"]
# }

# Lambda Function
resource "aws_lambda_function" "anigmaa_backend" {
  filename      = "lambda-function.zip"
  function_name = "${var.project_name}-backend"
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "bootstrap"
  runtime       = "provided.al2"
  timeout       = 30
  memory_size   = var.lambda_memory

  source_code_hash = filebase64sha256("lambda-function.zip")

  environment {
    variables = {
      PORT                  = "8080"
      ENV                   = var.environment
      DB_HOST               = aws_db_instance.anigmaa_db.address
      DB_PORT               = "5432"
      DB_USER               = var.db_username
      DB_NAME               = var.db_name
      DB_SSLMODE            = "require"
      REDIS_HOST            = aws_elasticache_replication_group.anigmaa_redis.primary_endpoint_address
      REDIS_PORT            = "6379"
      STORAGE_TYPE          = "s3"
      # AWS_REGION is reserved key in Lambda - already set automatically
      AWS_BUCKET            = aws_s3_bucket.anigmaa_uploads.bucket
      ALLOWED_ORIGINS       = var.allowed_origins
      MIDTRANS_CLIENT_KEY   = var.midtrans_client_key
      MIDTRANS_IS_PRODUCTION = "true"
    }
  }

  vpc_config {
    subnet_ids         = aws_subnet.private_subnets[*].id
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  # layers = [aws_lambda_layer_version.anigmaa_dependencies.arn]  # Uncomment if using lambda layer

  tags = {
    Name = "${var.project_name}-backend"
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_execution_role_policy,
    aws_iam_role_policy.lambda_s3_policy,
    aws_iam_role_policy.lambda_ssm_policy,
    aws_iam_role_policy.lambda_cloudwatch_policy
  ]
}

# Lambda Alias (Optional, for versioning)
resource "aws_lambda_alias" "anigmaa_backend_live" {
  name              = "live"
  function_name    = aws_lambda_function.anigmaa_backend.function_name
  function_version  = aws_lambda_function.anigmaa_backend.version
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${var.project_name}-backend"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-lambda-logs"
  }
}

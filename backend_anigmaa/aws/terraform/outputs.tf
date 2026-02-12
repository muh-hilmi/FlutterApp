output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.anigmaa_vpc.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public_subnets[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = aws_subnet.private_subnets[*].id
}

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.anigmaa_db.address
}

output "redis_endpoint" {
  description = "Redis cluster endpoint"
  value       = aws_elasticache_replication_group.anigmaa_redis.primary_endpoint_address
}

output "s3_bucket_name" {
  description = "S3 bucket name for uploads"
  value       = aws_s3_bucket.anigmaa_uploads.bucket
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.anigmaa_uploads.arn
}

# Lambda Outputs
output "lambda_function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.anigmaa_backend.function_name
}

output "lambda_function_arn" {
  description = "Lambda function ARN"
  value       = aws_lambda_function.anigmaa_backend.arn
}

output "lambda_role_arn" {
  description = "Lambda execution role ARN"
  value       = aws_iam_role.lambda_execution_role.arn
}

output "api_gateway_endpoint" {
  description = "API Gateway endpoint URL"
  value       = aws_apigatewayv2_stage.anigmaa_api_stage.invoke_url
}

output "api_gateway_id" {
  description = "API Gateway API ID"
  value       = aws_apigatewayv2_api.anigmaa_api.id
}

output "lambda_cloudwatch_log_group" {
  description = "CloudWatch log group for Lambda"
  value       = aws_cloudwatch_log_group.lambda_logs.name
}

output "api_gateway_cloudwatch_log_group" {
  description = "CloudWatch log group for API Gateway"
  value       = aws_cloudwatch_log_group.api_gateway_logs.name
}

# Optional: Custom Domain Mapping
output "custom_domain_name" {
  description = "Custom domain name (if configured)"
  value       = var.domain_name != "" ? aws_apigatewayv2_domain_name.anigmaa_custom_domain[0].domain_name : "Not configured"
}

# Deprecated ECS/Fargate Outputs
# output "ecr_repository_url" {
#   description = "ECR repository URL"
#   value       = aws_ecr_repository.anigmaa_backend.repository_url
# }
#
# output "ecs_cluster_name" {
#   description = "ECS cluster name"
#   value       = aws_ecs_cluster.anigmaa_cluster.name
# }
#
# output "ecs_service_name" {
#   description = "ECS service name"
#   value       = aws_ecs_service.anigmaa_backend.name
# }
#
# output "alb_dns_name" {
#   description = "Application Load Balancer DNS name"
#   value       = aws_lb.anigmaa_alb.dns_name
# }
#
# output "alb_zone_id" {
#   description = "Application Load Balancer Zone ID"
#   value       = aws_lb.anigmaa_alb.zone_id
# }
#
# output "alb_arn" {
#   description = "Application Load Balancer ARN"
#   value       = aws_lb.anigmaa_alb.arn
# }
#
# output "ecs_task_definition_arn" {
#   description = "ECS task definition ARN"
#   value       = aws_ecs_task_definition.anigmaa_backend.arn
# }
#
# output "ecs_task_role_arn" {
#   description = "ECS task role ARN"
#   value       = aws_iam_role.ecs_task_role.arn
# }
#
# output "ecs_execution_role_arn" {
#   description = "ECS execution role ARN"
#   value       = aws_iam_role.ecs_execution_role.arn
# }
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-1"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "anigmaa"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# Database variables
variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
  default     = 20
}

variable "db_max_allocated_storage" {
  description = "RDS max allocated storage in GB"
  type        = number
  default     = 100
}

variable "db_username" {
  description = "RDS master username"
  type        = string
  default     = "postgres"
}

variable "db_password" {
  description = "RDS master password"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "RDS database name"
  type        = string
  default     = "anigmaa"
}

# Redis variables
variable "redis_node_type" {
  description = "ElastiCache node type"
  type        = string
  default     = "cache.t3.micro"
}

variable "redis_parameter_group_name" {
  description = "ElastiCache parameter group"
  type        = string
  default     = "default.redis7"
}

# ECS variables - Deprecated (using Lambda instead)
# variable "ecs_cpu" {
#   description = "CPU units for ECS task"
#   type        = number
#   default     = 512
# }
#
# variable "ecs_memory" {
#   description = "Memory for ECS task"
#   type        = number
#   default     = 1024
# }
#
# variable "ecs_desired_count" {
#   description = "Desired number of ECS tasks"
#   type        = number
#   default     = 2
# }

# Lambda variables
variable "lambda_memory" {
  description = "Memory for Lambda function in MB"
  type        = number
  default     = 512
}

# S3 variables
variable "s3_bucket_name" {
  description = "S3 bucket name for file uploads"
  type        = string
  default     = "anigmaa-uploads"
}

# Application variables
variable "jwt_secret" {
  description = "JWT secret key"
  type        = string
  sensitive   = true
}

variable "midtrans_server_key" {
  description = "Midtrans server key"
  type        = string
  sensitive   = true
  default     = ""
}

variable "midtrans_client_key" {
  description = "Midtrans client key"
  type        = string
  default     = ""
}

variable "allowed_origins" {
  description = "CORS allowed origins"
  type        = string
  default     = "https://yourdomain.com"
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  default     = ""
}

variable "certificate_arn" {
  description = "SSL certificate ARN for HTTPS"
  type        = string
  default     = ""
}
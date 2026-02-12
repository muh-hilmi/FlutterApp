# ECR Repository - Deprecated (using Lambda instead of ECS/Fargate)
# Kept for reference if needed in the future
# resource "aws_ecr_repository" "anigmaa_backend" {
#   name                 = "${var.project_name}-backend"
#   image_tag_mutability = "MUTABLE"
#
#   image_scanning_configuration {
#     scan_on_push = true
#   }
#
#   tags = {
#     Name = "${var.project_name}-backend"
#   }
# }

# ECR Lifecycle Policy - Deprecated (using Lambda instead of ECS/Fargate)
# resource "aws_ecr_lifecycle_policy" "anigmaa_backend_lifecycle" {
#   repository = aws_ecr_repository.anigmaa_backend.name
#
#   policy = jsonencode({
#     rules = [
#       {
#         rulePriority = 1
#         description  = "Keep last 10 images"
#         selection = {
#           tagStatus     = "tagged"
#           tagPrefixList = ["v"]
#           countType     = "imageCountMoreThan"
#           countNumber   = 10
#         }
#         action = {
#           type = "expire"
#         }
#       },
#       {
#         rulePriority = 2
#         description  = "Delete untagged images older than 1 day"
#         selection = {
#           tagStatus   = "untagged"
#           countType   = "sinceImagePushed"
#           countUnit   = "days"
#           countNumber = 1
#         }
#         action = {
#           type = "expire"
#         }
#       }
#     ]
#   })
# }

# ECS Cluster - Deprecated (using Lambda instead of ECS/Fargate)
# resource "aws_ecs_cluster" "anigmaa_cluster" {
#   name = "${var.project_name}-cluster"
#
#   configuration {
#     execute_command_configuration {
#       logging = "OVERRIDE"
#       log_configuration {
#         cloud_watch_log_group_name = aws_cloudwatch_log_group.ecs_exec.name
#       }
#     }
#   }
#
#   tags = {
#     Name = "${var.project_name}-cluster"
#   }
# }

# CloudWatch Log Group for ECS - Deprecated (using Lambda instead of ECS/Fargate)
# resource "aws_cloudwatch_log_group" "anigmaa_backend" {
#   name              = "/ecs/${var.project_name}-backend"
#   retention_in_days = 7
#
#   tags = {
#     Name = "${var.project_name}-backend-logs"
#   }
# }

# CloudWatch Log Group for ECS Exec - Deprecated (using Lambda instead of ECS/Fargate)
# resource "aws_cloudwatch_log_group" "ecs_exec" {
#   name              = "/ecs/exec/${var.project_name}"
#   retention_in_days = 7
#
#   tags = {
#     Name = "${var.project_name}-ecs-exec-logs"
#   }
# }

# ECS Task Definition - Deprecated (using Lambda instead of ECS/Fargate)
# resource "aws_ecs_task_definition" "anigmaa_backend" {
#   family                   = "${var.project_name}-backend"
#   network_mode             = "awsvpc"
#   requires_compatibilities = ["FARGATE"]
#   cpu                      = var.ecs_cpu
#   memory                   = var.ecs_memory
#   execution_role_arn       = aws_iam_role.ecs_execution_role.arn
#   task_role_arn           = aws_iam_role.ecs_task_role.arn
#
#   container_definitions = jsonencode([
#     {
#       name      = "anigmaa-backend"
#       image     = "${aws_ecr_repository.anigmaa_backend.repository_url}:latest"
#       essential = true
#
#       portMappings = [
#         {
#           containerPort = 8080
#           protocol      = "tcp"
#         }
#       ]
#
#       environment = [
#         {
#           name  = "PORT"
#           value = "8080"
#         },
#         {
#           name  = "ENV"
#           value = var.environment
#         },
#         {
#           name  = "DB_HOST"
#           value = aws_db_instance.anigmaa_db.address
#         },
#         {
#           name  = "DB_PORT"
#           value = "5432"
#         },
#         {
#           name  = "DB_USER"
#           value = var.db_username
#         },
#         {
#           name  = "DB_NAME"
#           value = var.db_name
#         },
#         {
#           name  = "DB_SSLMODE"
#           value = "require"
#         },
#         {
#           name  = "REDIS_HOST"
#           value = aws_elasticache_replication_group.anigmaa_redis.primary_endpoint_address
#         },
#         {
#           name  = "REDIS_PORT"
#           value = "6379"
#         },
#         {
#           name  = "STORAGE_TYPE"
#           value = "s3"
#         },
#         {
#           name  = "AWS_REGION"
#           value = var.aws_region
#         },
#         {
#           name  = "AWS_BUCKET"
#           value = aws_s3_bucket.anigmaa_uploads.bucket
#         },
#         {
#           name  = "ALLOWED_ORIGINS"
#           value = var.allowed_origins
#         },
#         {
#           name  = "MIDTRANS_CLIENT_KEY"
#           value = var.midtrans_client_key
#         },
#         {
#           name  = "MIDTRANS_IS_PRODUCTION"
#           value = "true"
#         }
#       ]
#
#       secrets = [
#         {
#           name      = "DB_PASSWORD"
#           valueFrom = aws_ssm_parameter.db_password.arn
#         },
#         {
#           name      = "JWT_SECRET"
#           valueFrom = aws_ssm_parameter.jwt_secret.arn
#         },
#         {
#           name      = "REDIS_PASSWORD"
#           valueFrom = aws_ssm_parameter.redis_auth_token.arn
#         },
#         {
#           name      = "MIDTRANS_SERVER_KEY"
#           valueFrom = aws_ssm_parameter.midtrans_server_key.arn
#         }
#       ]
#
#       logConfiguration = {
#         logDriver = "awslogs"
#         options = {
#           awslogs-group         = aws_cloudwatch_log_group.anigmaa_backend.name
#           awslogs-region        = var.aws_region
#           awslogs-stream-prefix = "ecs"
#         }
#       }
#
#       healthCheck = {
#         command = [
#           "CMD-SHELL",
#           "wget --quiet --tries=1 --spider http://localhost:8080/health || exit 1"
#         ]
#         interval    = 30
#         timeout     = 5
#         retries     = 3
#         startPeriod = 60
#       }
#     }
#   ])
#
#   tags = {
#     Name = "${var.project_name}-backend-task"
#   }
# }

# ECS Service - Deprecated (using Lambda instead of ECS/Fargate)
# resource "aws_ecs_service" "anigmaa_backend" {
#   name            = "${var.project_name}-backend"
#   cluster         = aws_ecs_cluster.anigmaa_cluster.id
#   task_definition = aws_ecs_task_definition.anigmaa_backend.arn
#   desired_count   = var.ecs_desired_count
#   launch_type     = "FARGATE"
#
#   network_configuration {
#     subnets          = aws_subnet.private_subnets[*].id
#     security_groups  = [aws_security_group.ecs_sg.id]
#     assign_public_ip = false
#   }
#
#   load_balancer {
#     target_group_arn = aws_lb_target_group.anigmaa_backend.arn
#     container_name   = "anigmaa-backend"
#     container_port   = 8080
#   }
#
#   depends_on = [
#     aws_lb_listener.anigmaa_backend,
#     aws_iam_role_policy_attachment.ecs_execution_role_policy
#   ]
#
#   tags = {
#     Name = "${var.project_name}-backend-service"
#   }
# }

# Auto Scaling Target - Deprecated (using Lambda instead of ECS/Fargate)
# resource "aws_appautoscaling_target" "anigmaa_backend" {
#   max_capacity       = 10
#   min_capacity       = 2
#   resource_id        = "service/${aws_ecs_cluster.anigmaa_cluster.name}/${aws_ecs_service.anigmaa_backend.name}"
#   scalable_dimension = "ecs:service:DesiredCount"
#   service_namespace  = "ecs"
# }

# Auto Scaling Policy - CPU - Deprecated (using Lambda instead of ECS/Fargate)
# resource "aws_appautoscaling_policy" "anigmaa_backend_cpu" {
#   name               = "${var.project_name}-backend-cpu"
#   policy_type        = "TargetTrackingScaling"
#   resource_id        = aws_appautoscaling_target.anigmaa_backend.resource_id
#   scalable_dimension = aws_appautoscaling_target.anigmaa_backend.scalable_dimension
#   service_namespace  = aws_appautoscaling_target.anigmaa_backend.service_namespace
#
#   target_tracking_scaling_policy_configuration {
#     predefined_metric_specification {
#       predefined_metric_type = "ECSServiceAverageCPUUtilization"
#     }
#     target_value = 70.0
#   }
# }

# Auto Scaling Policy - Memory - Deprecated (using Lambda instead of ECS/Fargate)
# resource "aws_appautoscaling_policy" "anigmaa_backend_memory" {
#   name               = "${var.project_name}-backend-memory"
#   policy_type        = "TargetTrackingScaling"
#   resource_id        = aws_appautoscaling_target.anigmaa_backend.resource_id
#   scalable_dimension = aws_appautoscaling_target.anigmaa_backend.scalable_dimension
#   service_namespace  = aws_appautoscaling_target.anigmaa_backend.service_namespace
#
#   target_tracking_scaling_policy_configuration {
#     predefined_metric_specification {
#       predefined_metric_type = "ECSServiceAverageMemoryUtilization"
#     }
#     target_value = 80.0
#   }
# }
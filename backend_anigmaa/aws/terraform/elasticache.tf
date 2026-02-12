# ElastiCache Subnet Group
resource "aws_elasticache_subnet_group" "anigmaa_redis_subnet_group" {
  name       = "${var.project_name}-redis-subnet-group"
  subnet_ids = aws_subnet.private_subnets[*].id

  tags = {
    Name = "${var.project_name}-redis-subnet-group"
  }
}

# ElastiCache Redis Cluster
resource "aws_elasticache_replication_group" "anigmaa_redis" {
  replication_group_id         = "${var.project_name}-redis"
  description                  = "Redis cluster for ${var.project_name}"

  # Engine
  engine               = "redis"
  engine_version       = "7.0"
  node_type           = var.redis_node_type
  port                = 6379

  # Cluster configuration
  num_cache_clusters = 2

  # Network
  subnet_group_name  = aws_elasticache_subnet_group.anigmaa_redis_subnet_group.name
  security_group_ids = [aws_security_group.redis_sg.id]

  # Parameters
  parameter_group_name = var.redis_parameter_group_name

  # Security
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token                 = random_password.redis_auth_token.result

  # Backup
  snapshot_retention_limit = 3
  snapshot_window         = "03:00-05:00"

  # Maintenance
  maintenance_window = "sun:05:00-sun:07:00"

  # Automatic failover
  automatic_failover_enabled = true
  multi_az_enabled          = true

  tags = {
    Name = "${var.project_name}-redis"
  }
}

# Generate random password for Redis AUTH
# Redis AUTH tokens only support alphanumeric characters (no special chars)
resource "random_password" "redis_auth_token" {
  length  = 32
  special = false
  upper   = true
  lower   = true
  numeric = true
}

# Store Redis auth token in Parameter Store
resource "aws_ssm_parameter" "redis_auth_token" {
  name  = "/${var.project_name}/${var.environment}/redis/auth-token"
  type  = "SecureString"
  value = random_password.redis_auth_token.result

  tags = {
    Name = "${var.project_name}-redis-auth-token"
  }
}
# SSM Parameters for storing sensitive configuration

# Database password
resource "aws_ssm_parameter" "db_password" {
  name  = "/${var.project_name}/${var.environment}/db/password"
  type  = "SecureString"
  value = var.db_password

  tags = {
    Name = "${var.project_name}-db-password"
  }
}

# JWT Secret
resource "aws_ssm_parameter" "jwt_secret" {
  name  = "/${var.project_name}/${var.environment}/jwt/secret"
  type  = "SecureString"
  value = var.jwt_secret

  tags = {
    Name = "${var.project_name}-jwt-secret"
  }
}

# Midtrans Server Key
resource "aws_ssm_parameter" "midtrans_server_key" {
  name  = "/${var.project_name}/${var.environment}/midtrans/server-key"
  type  = "SecureString"
  value = var.midtrans_server_key

  tags = {
    Name = "${var.project_name}-midtrans-server-key"
  }
}
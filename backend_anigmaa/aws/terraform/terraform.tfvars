# AWS Configuration
aws_region = "ap-southeast-1"

# Project Configuration
project_name = "anigmaa"
environment  = "prod"

# Network Configuration
vpc_cidr = "10.0.0.0/16"

# Database Configuration
db_instance_class        = "db.t3.micro"
db_allocated_storage     = 20
db_max_allocated_storage = 100
db_username              = "postgres"
db_password              = "WRGCZxHhGRp0vFXY"
db_name                  = "anigmaa"

# Redis Configuration
redis_node_type            = "cache.t3.micro"
redis_parameter_group_name = "default.redis7"

# Lambda Configuration
lambda_memory = 512  # MB

# S3 Configuration
s3_bucket_name = "anigmaa-uploads"  # Will auto-append account ID

# Application Configuration
jwt_secret          = "2GeflZcneQfck7uttwoQTI085VaIhwBg"
midtrans_server_key = "YOUR_MIDTRANS_SERVER_KEY"
midtrans_client_key = "YOUR_MIDTRANS_CLIENT_KEY"
allowed_origins     = "https://muhhilmi.site,https://api.muhhilmi.site"

# Cloudflare Configuration
# Domain dan subdomain will be set up via Cloudflare DNS (not AWS custom domain)
domain_name     = ""  # Leave empty - using Cloudflare for DNS
certificate_arn = ""  # Leave empty - Cloudflare handles SSL/TLS

# Cloudflare Details (for reference)
# Root Domain: muhhilmi.site
# API Subdomain: api.muhhilmi.site
# DNS: CNAME from Cloudflare pointing to API Gateway endpoint
# SSL: Cloudflare Universal SSL
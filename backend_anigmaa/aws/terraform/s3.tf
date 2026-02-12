# S3 Bucket for file uploads
resource "aws_s3_bucket" "anigmaa_uploads" {
  bucket = "${var.s3_bucket_name}-${random_id.bucket_suffix.hex}"

  tags = {
    Name = "${var.project_name}-uploads"
  }
}

# Generate random suffix for bucket name to ensure uniqueness
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "anigmaa_uploads_versioning" {
  bucket = aws_s3_bucket.anigmaa_uploads.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket Server Side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "anigmaa_uploads_encryption" {
  bucket = aws_s3_bucket.anigmaa_uploads.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket Public Access Block
resource "aws_s3_bucket_public_access_block" "anigmaa_uploads_pab" {
  bucket = aws_s3_bucket.anigmaa_uploads.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket Policy for ECS Task Access
resource "aws_s3_bucket_policy" "anigmaa_uploads_policy" {
  bucket = aws_s3_bucket.anigmaa_uploads.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowECSTaskAccess"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.ecs_task_role.arn
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "${aws_s3_bucket.anigmaa_uploads.arn}/*"
      },
      {
        Sid    = "AllowECSTaskListBucket"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.ecs_task_role.arn
        }
        Action   = "s3:ListBucket"
        Resource = aws_s3_bucket.anigmaa_uploads.arn
      }
    ]
  })
}

# S3 Bucket CORS Configuration
resource "aws_s3_bucket_cors_configuration" "anigmaa_uploads_cors" {
  bucket = aws_s3_bucket.anigmaa_uploads.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "DELETE", "HEAD"]
    allowed_origins = split(",", var.allowed_origins)
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

# S3 Bucket Lifecycle Configuration
resource "aws_s3_bucket_lifecycle_configuration" "anigmaa_uploads_lifecycle" {
  bucket = aws_s3_bucket.anigmaa_uploads.id

  rule {
    id     = "delete_incomplete_multipart_uploads"
    status = "Enabled"
    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }

  rule {
    id     = "transition_to_ia"
    status = "Enabled"
    filter {}

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    transition {
      days          = 365
      storage_class = "DEEP_ARCHIVE"
    }
  }
}
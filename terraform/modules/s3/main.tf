data "aws_caller_identity" "current" {}
# Define an S3 bucket resource
resource "aws_s3_bucket" "log_bucket" {
  bucket = var.log_bucket_name
  tags   = var.common_tags
}

# Enable versioning for the S3 bucket
resource "aws_s3_bucket_versioning" "log_versioning" {
  bucket = aws_s3_bucket.log_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption for the S3 bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "log_encryption" {
  bucket = aws_s3_bucket.log_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access to the S3 bucket
resource "aws_s3_bucket_public_access_block" "log_bucket_restrictions" {
  bucket = aws_s3_bucket.log_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = true
  restrict_public_buckets = false
}

# Define lifecycle rules for the S3 bucket
resource "aws_s3_bucket_lifecycle_configuration" "log_lifecycle" {
  bucket = aws_s3_bucket.log_bucket.id

  rule {
    id     = "expire-logs"
    status = "Enabled"

    expiration {
      days = var.log_retention_days
    }
  }
}

# Define a bucket policy for the S3 bucket
resource "aws_s3_bucket_policy" "log_bucket_policy" {
  count  = var.enable_s3_logs ? 1 : 0
  bucket = aws_s3_bucket.log_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [

      # Allow VPC Flow Logs to write to S3
      {
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.log_bucket.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl"      = "bucket-owner-full-control"
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      },

      # Allow ALB to write logs to S3
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${lookup(var.alb_account_ids, var.aws_region, "UNKNOWN")}:root"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.log_bucket.arn}/AWSLogs/${var.alb_log_prefix}/*"
      },

      # Allow CloudTrail logging (if needed)
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.log_bucket.arn}/AWSLogs/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },

      # Allow the bucket owner full control
      {
        Effect   = "Allow"
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.log_bucket.arn
      }
    ]
  })
}

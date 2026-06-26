variable "log_bucket_name" {
  description = "The name of the S3 bucket for storing VPC Flow Logs & ALB Access Logs"
  type        = string
}

variable "alb_log_prefix" {
  description = "Prefix for ALB logs in the S3 bucket"
  type        = string
  default     = "alb-logs/"
}

variable "vpc_log_prefix" {
  description = "Prefix for VPC Flow logs in the S3 bucket"
  type        = string
  default     = "vpc-flow-logs/"
}

variable "log_retention_days" {
  description = "Number of days to retain logs before deletion"
  type        = number
  default     = 30
}

variable "aws_region" {
  description = "AWS region where resources will be deployed"
  type        = string
}

variable "alb_account_ids" {
  description = "AWS ALB service account IDs for different regions"
  type        = map(string)
  default = {
    "us-east-2" = "033677994240"
  }
}

variable "common_tags" {
  description = "Common tags"
  type        = map(string)
}

variable "enable_s3_logs" {
  description = "Whether to enable S3 logging permissions"
  type        = bool
  default     = false
}

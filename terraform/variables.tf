#------------------------------------------------------------------------------
# VPC Variables
#------------------------------------------------------------------------------
variable "project" {
  type    = string
  default = "demo"
}

variable "name" {
  type    = string
  default = "node-app"
}

variable "env" {
  type    = string
  default = "test"
}
variable "region" {
  type    = string
  default = "us-east-2"
}

variable "private_subnet_1_cidr" {
  type = string
}
variable "private_subnet_2_cidr" {
  type = string
}
variable "public_subnet_1_cidr" {
  type = string
}
variable "public_subnet_2_cidr" {
  type = string
}
variable "vpc_cidr" {
  type = string
}

#------------------------------------------------------------------------------
# CW Log Group Variables
#------------------------------------------------------------------------------


variable "create_kms_key" {
  description = "If true a new KMS key will be created to encrypt the logs. Defaults true. If set to false a custom key can be used by setting the variable `log_group_kms_key_id`"
  type        = bool
  default     = false
}

variable "log_group_kms_key_id" {
  description = "The ARN of the KMS Key to use when encrypting log data. Please note, after the AWS KMS CMK is disassociated from the log group, AWS CloudWatch Logs stops encrypting newly ingested data for the log group. All previously ingested data remains encrypted, and AWS CloudWatch Logs requires permissions for the CMK whenever the encrypted data is requested."
  type        = string
  default     = null
}

variable "log_group_retention_in_days" {
  description = "(Optional) Specifies the number of days you want to retain log events in the specified log group. Possible values are: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653, and 0. If you select 0, the events in the log group are always retained and never expire. Default to 30 days."
  type        = number
  default     = 30
}

#------------------------------------------------------------------------------
# ECR Repository
#------------------------------------------------------------------------------

variable "ecr_repository" {
  type        = string
  description = "A list of ECR repositories to create"
  default     = "node-app"
}

#------------------------------------------------------------------------------
# ECS Cluster Variables
#------------------------------------------------------------------------------

variable "containerInsights" {
  description = "Enables container insights if true"
  type        = bool
  default     = false
}

#------------------------------------------------------------------------------
# Application Load Balancer
#------------------------------------------------------------------------------

variable "lb_http_ports" {
  description = "HTTP listener and target group configuration"
  type        = map(any)
  default = {
    default_http = {
      type              = "forward"
      listener_port     = 80
      target_group_port = 3000
    }
  }
}

variable "lb_https_ports" {
  description = "HTTPS listener and target group configuration"
  type        = map(any)
  default     = {}
}

variable "lb_enable_cross_zone_load_balancing" {
  type        = string
  default     = "true"
  description = "Enable cross zone support for LB"
}

variable "http_ingress_cidr_blocks" {
  description = "List of CIDR blocks to allowed to access the Load Balancer through HTTP"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "https_ingress_cidr_blocks" {
  description = "List of CIDR blocks to allowed to access the Load Balancer through HTTP"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
#------------------------------------------------------------------------------
# Application Load Balancer Logging
#------------------------------------------------------------------------------

variable "enable_s3_logs" {
  description = "(Optional) If true, all resources to send LB logs to S3 will be created"
  type        = bool
  default     = true
}

variable "block_s3_bucket_public_access" {
  description = "(Optional) If true, public access to the S3 bucket will be blocked."
  type        = bool
  default     = true
}

variable "enable_s3_bucket_server_side_encryption" {
  description = "(Optional) If true, server side encryption will be applied."
  type        = bool
  default     = true
}

variable "s3_bucket_server_side_encryption_sse_algorithm" {
  description = "(Optional) The server-side encryption algorithm to use. Valid values are AES256 and aws:kms"
  type        = string
  default     = "AES256"
}

variable "s3_bucket_server_side_encryption_key" {
  description = "(Optional) The AWS KMS master key ID used for the SSE-KMS encryption. This can only be used when you set the value of sse_algorithm as aws:kms. The default aws/s3 AWS KMS master key is used if this element is absent while the sse_algorithm is aws:kms."
  type        = string
  default     = null
}

#------------------------------------------------------------------------------
# Task Definition Variables
#------------------------------------------------------------------------------

variable "URL" {
  type = string
}

variable "secret_arn" {
  type = string
}

#------------------------------------------------------------------------------
# KMS Variables
#------------------------------------------------------------------------------

variable "alias" {
  description = "Alias for the KMS key"
  type        = string
  default     = "alias/aws/cw"
}

variable "common_tags" {
  description = "Common tags to be applied to all resources"
  type        = map(string)
  default = {
    Name        = "node-app"
    Environment = "test"
    Project     = "hire"
    Owner       = "Data Engineering Team"
    CostCenter  = "12345"
    Department  = "Engineering"
    ManagedBy   = "Terraform"
    CreatedBy   = "GitHub Actions"
  }
}

#------------------------------------------------------------------------------
# Route53 Variables
#------------------------------------------------------------------------------

variable "domain_name" {
  type = string
}

variable "hosted_zone_id" {
  type = string
}

#------------------------------------------------------------------------------
# S3 Variables
#------------------------------------------------------------------------------
variable "log_bucket_name" {
  description = "The name of the S3 bucket for storing VPC Flow Logs & ALB Access Logs"
  type        = string
}

#------------------------------------------------------------------------------
# Waf Variables
#------------------------------------------------------------------------------

variable "waf_name" {
  description = "Name of the WAF WebACL"
  type        = string
  default     = "my-waf-webacl"
}

variable "enable_waf" {
  description = "Enable WAF if true"
  type        = bool
  default     = false
}

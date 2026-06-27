#------------------------------------------------------------------------------
# Environment Specific Variables logs
#------------------------------------------------------------------------------
variable "name" {
  type = string
}


variable "environment" {
  type = string
}

variable "region" {
  type = string
}

variable "project" {
  type = string
}

variable "common_tags" {
  description = "Common tags"
  type        = map(string)
}

#------------------------------------------------------------------------------
# CloudWatch logs
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

variable "kms_key_id" {
  type = string
}

#------------------------------------------------------------------------------
# ECR Repository Variables
#------------------------------------------------------------------------------
variable "ecr_repository_name" {
  type = string
}

variable "ecr_pull_accounts" {
  type        = list(string)
  description = "A list of AWS accounts that will have pull access from ECR repositories"
  default = [
    "637423357784",
    "589077667712" # test account
  ]
}

#------------------------------------------------------------------------------
# SG Variables
#------------------------------------------------------------------------------

variable "remote_cidr_blocks" {
  type        = list(any)
  default     = ["10.0.0.0/16"]
  description = "By default cidr_blocks are locked down. (Update to 0.0.0.0/0 if full public access is needed)"
}

variable "vpc_id" {
  type = string
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

variable "lb_enable_cross_zone_load_balancing" {
  type        = string
  default     = "true"
  description = "Enable cross zone support for LB"
}

variable "lb_https_ports" {
  description = "HTTPS listener and target group configuration"
  type        = map(any)
  default     = {}
}

variable "lb_http_ports" {
  description = "Map containing objects to define listeners behaviour based on type field. If type field is `forward`, include listener_port and the target_group_port. For `redirect` type, include listener port, host, path, port, protocol, query and status_code. For `fixed-response`, include listener_port, content_type, message_body and status_code"
  type        = map(any)
  default = {
    force-https = {
      type          = "redirect"
      listener_port = 80
      host          = "#{host}"
      path          = "/#{path}"
      port          = "443"
      protocol      = "HTTPS"
      query         = "#{query}"
      status_code   = "HTTP_301"
    }
  }
}

variable "public_subnets" {
  type        = list(any)
  description = "List of Public Subnets IDs"
}

variable "private_subnets" {
  type        = list(any)
  description = "List of Private Subnets IDs"
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
  default     = false
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

variable "log_bucket_id" {
  description = "The ID of the S3 bucket to store the logs"
  type        = string
  default     = ""
}

variable "access_logs_prefix" {
  description = "The prefix to be used for the access logs"
  type        = string
  default     = "alb-logs"
}

#------------------------------------------------------------------------------
# Task Definition Variables
#------------------------------------------------------------------------------

variable "container_cpu" {
  description = "(Optional) The number of cpu units to reserve for the container. This is optional for tasks using Fargate launch type and the total amount of container_cpu of all containers in a task will need to be lower than the task-level cpu value"
  type        = number
  default     = 2048
}

variable "container_memory" {
  description = "(Optional) The amount of memory (in MiB) to allow the container to use. This is a hard limit, if the container attempts to exceed the container_memory, the container is killed. This field is optional for Fargate launch type and the total amount of container_memory of all containers in a task will need to be lower than the task memory value"
  type        = number
  default     = 4096
}

variable "container_memory_reservation" {
  description = "(Optional) The amount of memory (in MiB) to reserve for the container. If container needs to exceed this threshold, it can do so up to the set container_memory hard limit"
  type        = number
  default     = 4096
}

variable "image_version" {
  type    = string
  default = "latest"
}

variable "URL" {
  type = string
}

variable "secret_arn" {
  type = string
}

#------------------------------------------------------------------------------
# ECS Service Variables
#------------------------------------------------------------------------------

variable "assign_public_ip" {
  description = "(Optional) You can enable the deployment circuit breaker to cause a service deployment to transition to a failed state if tasks are persistently failing to reach RUNNING state or are failing healthcheck."
  type        = bool
  default     = false
}

variable "enable_autoscaling" {
  description = "(Optional) You can enable the deployment circuit breaker to cause a service deployment to transition to a failed state if tasks are persistently failing to reach RUNNING state or are failing healthcheck."
  type        = bool
  default     = true
}

variable "enable_execute_command" {
  description = "(Optional) You can enable the deployment circuit breaker to cause a service deployment to transition to a failed state if tasks are persistently failing to reach RUNNING state or are failing healthcheck."
  type        = bool
  default     = true
}

# variable "certificate_arn" {
#   description = "ACM certificate ARN for the HTTPS listener"
#   type        = string
# }

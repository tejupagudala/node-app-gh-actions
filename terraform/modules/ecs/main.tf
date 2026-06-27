#------------------------------------------------------------------------------
# AWS Cloudwatch Logs
#------------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name              = "/ecs/service/${var.environment}-${var.name}"
  retention_in_days = 30
  kms_key_id        = var.kms_key_id
  tags              = var.common_tags
}

#------------------------------------------------------------------------------
# ECS TaskExecution Role
#------------------------------------------------------------------------------
resource "aws_iam_role" "ECSTaskExecutionRole" {
  name_prefix = var.name

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })

  tags = var.common_tags
}

#------------------------------------------------------------------------------
# ECR Repository Creation
#------------------------------------------------------------------------------
resource "aws_ecr_repository" "main" {
  name                 = var.ecr_repository_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository_policy" "ecr_policies" {
  repository = aws_ecr_repository.main.name
  policy     = data.aws_iam_policy_document.ecr_cross_account_access.json
}

data "aws_iam_policy_document" "ecr_cross_account_access" {
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [for account in var.ecr_pull_accounts : "arn:aws:iam::${account}:root"]
    }
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetLifecyclePolicy",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart"
    ]
  }
}

#------------------------------------------------------------------------------
# Security Group Creation
#------------------------------------------------------------------------------
# ######
# # Security Groups
# ######
resource "aws_security_group" "fargate_container_sg" {
  description = "Allow access to the public facing load balancer"
  vpc_id      = var.vpc_id

  ingress {
    description = "Ingress from the public ALB"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.remote_cidr_blocks
  }
  ingress {
    description = "Ingress from the private ALB"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
  }
  ingress {
    description = "Ingress from other containers in the same security group"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.common_tags
}

resource "aws_security_group" "ecs_tasks" {
  name        = "${var.environment}-${var.name}-ecs-tasks-sg"
  description = "allow inbound access from the ALB only"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow inbound traffic from ALB on port 3000"
    protocol        = "tcp"
    from_port       = 3000
    to_port         = 3000
    security_groups = [module.ecs-alb.aws_security_group_lb_access_sg_id]
  }
  egress {
    description = "Allow all outbound traffic"
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = var.common_tags
}

resource "aws_security_group" "vpc_endpoint_sg" {
  name        = "allow_traffic_from_ECS"
  description = "Allow inbound traffic from ECS"
  vpc_id      = var.vpc_id

  ingress {
    description     = "TLS from VPC"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks.id]
  }
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = var.common_tags
}

#------------------------------------------------------------------------------
# ECS Cluster
#------------------------------------------------------------------------------
module "ecs-cluster" {
  source  = "cn-terraform/ecs-cluster/aws"
  version = "1.0.10"

  name              = "${var.environment}-${var.name}"
  tags              = var.common_tags
  containerInsights = var.containerInsights
}

#------------------------------------------------------------------------------
# AWS LOAD BALANCER
#------------------------------------------------------------------------------

# data "aws_acm_certificate" "node_app_cert" {
#   domain   = "*.demoprojectbc1.com"
#   statuses = ["ISSUED"]
# }

module "ecs-alb" {

  source  = "cn-terraform/ecs-alb/aws"
  version = "1.0.31"


  name_prefix = var.name
  vpc_id      = var.vpc_id

  

  # Application Load Balancer Logs
  enable_s3_logs = var.enable_s3_logs
  #log_bucket_id                                  = var.log_bucket_id
  access_logs_prefix                             = var.access_logs_prefix
  block_s3_bucket_public_access                  = var.block_s3_bucket_public_access
  enable_s3_bucket_server_side_encryption        = var.enable_s3_bucket_server_side_encryption
  s3_bucket_server_side_encryption_sse_algorithm = var.s3_bucket_server_side_encryption_sse_algorithm
  s3_bucket_server_side_encryption_key           = var.s3_bucket_server_side_encryption_key

  # Application Load Balancer
  private_subnets                  = var.private_subnets
  public_subnets                   = var.public_subnets
  enable_cross_zone_load_balancing = var.lb_enable_cross_zone_load_balancing
  # default_certificate_arn          = var.certificate_arn
  # Access Control to Application Load Balancer
  http_ports                = var.lb_http_ports
  https_ports               = var.lb_https_ports
  http_ingress_cidr_blocks  = var.http_ingress_cidr_blocks
  https_ingress_cidr_blocks = var.https_ingress_cidr_blocks

}

#------------------------------------------------------------------------------
# ECS Service and Task Definition
#------------------------------------------------------------------------------

data "aws_iam_policy_document" "secret-manager" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetResourcePolicy",
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecretVersionIds",
      "secretsmanager:GetRandomPassword",
      "secretsmanager:ListSecrets",
      "cloudwatch:PutMetricData"
    ]
    resources = ["*"]
  }
}

#------------------------------------------------------------------------------
# ECS Task Definition
#------------------------------------------------------------------------------
module "td" {
  source  = "cn-terraform/ecs-fargate-task-definition/aws"
  version = "1.0.35"

  name_prefix                             = var.project
  container_name                          = var.name
  container_image                         = "${aws_ecr_repository.main.repository_url}:${var.image_version}"
  container_memory                        = var.container_memory
  container_memory_reservation            = var.container_memory_reservation
  container_cpu                           = var.container_cpu
  ecs_task_execution_role_custom_policies = [data.aws_iam_policy_document.secret-manager.json]
  port_mappings = [
    {
      containerPort = 3000
      hostPort      = 3000
      protocol      = "tcp"
    }
  ]
  environment = [
    {
      name  = "URL"
      value = "${var.URL}"
    },
  ]
  secrets = [
    {
      name      = "API_KEY"
      valueFrom = "${var.secret_arn}:API_KEY::"
    },
  ]
  log_configuration = {
    logDriver = "awslogs"
    options = {
      "awslogs-region"        = var.region
      "awslogs-group"         = "/ecs/service/${var.environment}-${var.name}"
      "awslogs-stream-prefix" = "ecs"
    }
    secretOptions = null
  }
  ulimits = [
    {
      name      = "nofile"
      hardLimit = 65536
      softLimit = 65536
    }
  ]
}

#------------------------------------------------------------------------------
# ECS Service
#------------------------------------------------------------------------------

resource "aws_ecs_service" "node-app" {
  name                   = "${var.environment}-${var.name}"
  cluster                = module.ecs-cluster.aws_ecs_cluster_cluster_id
  task_definition        = module.td.aws_ecs_task_definition_td_arn
  desired_count          = 1
  launch_type            = "FARGATE"
  enable_execute_command = var.enable_execute_command

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = var.assign_public_ip ? var.public_subnets : var.private_subnets
    assign_public_ip = var.assign_public_ip
  }

  load_balancer {
    target_group_arn = module.ecs-alb.lb_http_tgs_arns[0]
    container_name   = var.name
    container_port   = 3000
  }

  depends_on = [
    module.ecs-alb,
    module.td
  ]
}


module "ecs-autoscaling" {
  count = var.enable_autoscaling ? 1 : 0

  source  = "cn-terraform/ecs-service-autoscaling/aws"
  version = "1.0.6"

  name_prefix      = var.name
  ecs_cluster_name = "${var.environment}-${var.name}"
  ecs_service_name = aws_ecs_service.node-app.name

}

# Fetching the AWS account details
data "aws_caller_identity" "current" {}

# VPC Module
module "vpc" {
  source = "./modules/vpc"

  project               = var.project
  env                   = var.env
  region                = var.region
  private_subnet_1_cidr = var.private_subnet_1_cidr
  private_subnet_2_cidr = var.private_subnet_2_cidr
  public_subnet_1_cidr  = var.public_subnet_1_cidr
  public_subnet_2_cidr  = var.public_subnet_2_cidr
  vpc_cidr              = var.vpc_cidr
  common_tags           = var.common_tags
  s3_bucket_arn         = module.s3.log_bucket_arn
}

# KMS Module
module "kms" {
  source         = "./modules/kms"
  environment    = var.env
  common_tags    = var.common_tags
  aws_account_id = data.aws_caller_identity.current.account_id
  alias          = var.alias
  region         = var.region
}

# ACM certificate
# resource "aws_acm_certificate" "node_app" {
#   domain_name       = var.domain_name
#   validation_method = "DNS"

#   lifecycle {
#     create_before_destroy = true
#   }

#   tags = var.common_tags
# }

# DNS records used to prove domain ownership
# resource "aws_route53_record" "certificate_validation" {
#   for_each = {
#     for option in aws_acm_certificate.node_app.domain_validation_options :
#     option.domain_name => {
#       name   = option.resource_record_name
#       record = option.resource_record_value
#       type   = option.resource_record_type
#     }
#   }

#   zone_id = var.hosted_zone_id
#   name    = each.value.name
#   type    = each.value.type
#   records = [each.value.record]
#   ttl     = 60
# }

# Wait until ACM validates and issues the certificate
# resource "aws_acm_certificate_validation" "node_app" {
#   certificate_arn = aws_acm_certificate.node_app.arn

#   validation_record_fqdns = [
#     for record in aws_route53_record.certificate_validation :
#     record.fqdn
#   ]
# }

# ECS Module
module "ecs" {
  source = "./modules/ecs"



  environment                                    = var.env
  region                                         = var.region
  name                                           = var.name
  project                                        = var.project
  log_group_kms_key_id                           = var.log_group_kms_key_id
  log_group_retention_in_days                    = var.log_group_retention_in_days
  create_kms_key                                 = var.create_kms_key
  ecr_repository_name                            = var.ecr_repository
  vpc_id                                         = module.vpc.vpc_id
  containerInsights                              = var.containerInsights
  lb_enable_cross_zone_load_balancing            = var.lb_enable_cross_zone_load_balancing
  lb_http_ports                                  = var.lb_http_ports
  lb_https_ports                                 = var.lb_https_ports
  http_ingress_cidr_blocks                       = var.http_ingress_cidr_blocks
  https_ingress_cidr_blocks                      = var.https_ingress_cidr_blocks
  enable_s3_logs                                 = var.enable_s3_logs
  log_bucket_id                                  = module.s3.log_bucket_id
  block_s3_bucket_public_access                  = var.block_s3_bucket_public_access
  enable_s3_bucket_server_side_encryption        = var.enable_s3_bucket_server_side_encryption
  s3_bucket_server_side_encryption_sse_algorithm = var.s3_bucket_server_side_encryption_sse_algorithm
  s3_bucket_server_side_encryption_key           = var.s3_bucket_server_side_encryption_key
  public_subnets                                 = module.vpc.public_subnet_ids
  private_subnets                                = module.vpc.private_subnet_ids
  URL                                            = var.URL
  secret_arn                                     = var.secret_arn
  kms_key_id                                     = module.kms.kms_key_arn
  common_tags                                    = var.common_tags
}

# Route53 Module
# module "route53" {
#   source         = "./modules/route53"
#   alb_dns_name   = module.ecs.aws_lb_lb_dns_name
#   alb_zone_id    = module.ecs.aws_lb_lb_zone_id
#   domain_name    = var.domain_name
#   hosted_zone_id = var.hosted_zone_id
# }

# S3 Module
module "s3" {
  source          = "./modules/s3"
  log_bucket_name = var.log_bucket_name
  common_tags     = var.common_tags
  aws_region      = var.region
  enable_s3_logs  = var.enable_s3_logs
}

#WAF Module
module "waf" {
  count       = var.enable_waf ? 1 : 0
  source      = "./modules/waf"
  waf_name    = var.waf_name
  common_tags = var.common_tags
  aws_region  = var.region
  alb_arn     = module.ecs.aws_lb_lb_arn
}

resource "aws_s3_bucket" "primary_dr_test" {
  # Primary-region bucket used as the replication source.
  bucket = var.primary_bucket_name

  tags = {
    Name   = "primary-dr-test"
    Region = var.region
    Role   = "primary"
  }
}

resource "aws_s3_bucket_versioning" "primary_dr_test" {
  # Versioning is required on the source bucket for S3 replication.
  bucket = aws_s3_bucket.primary_dr_test.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket" "dr_test" {
  # DR-region bucket created through the aliased provider.
  provider = aws.dr
  bucket   = var.dr_bucket_name

  tags = {
    Name   = "dr-test"
    Region = var.dr_region
    Role   = "dr"
  }
}

resource "aws_s3_bucket_versioning" "dr_test" {
  # Versioning is also required on the destination bucket.
  provider = aws.dr
  bucket   = aws_s3_bucket.dr_test.id

  versioning_configuration {
    status = "Enabled"
  }
}

data "aws_iam_policy_document" "s3_replication_assume_role" {
  # Trust policy so the S3 service can assume the replication role.
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "s3_replication" {
  # IAM role assumed by S3 when it copies objects to the DR bucket.
  count = var.enable_dr_replication ? 1 : 0
  name  = "${var.project}-${var.name}-${var.env}-s3-replication"

  assume_role_policy = data.aws_iam_policy_document.s3_replication_assume_role.json
}

data "aws_iam_policy_document" "s3_replication" {
  # Permissions S3 needs to read from the source bucket and write to the DR bucket.
  statement {
    effect = "Allow"
    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket",
    ]
    resources = [
      aws_s3_bucket.primary_dr_test.arn,
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
    ]
    resources = [
      "${aws_s3_bucket.primary_dr_test.arn}/*",
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags",
    ]
    resources = [
      "${aws_s3_bucket.dr_test.arn}/*",
    ]
  }
}

resource "aws_iam_policy" "s3_replication" {
  # Managed policy created from the replication permissions document.
  count  = var.enable_dr_replication ? 1 : 0
  name   = "${var.project}-${var.name}-${var.env}-s3-replication"
  policy = data.aws_iam_policy_document.s3_replication.json
}

resource "aws_iam_role_policy_attachment" "s3_replication" {
  # Attaches the replication policy to the role assumed by S3.
  count      = var.enable_dr_replication ? 1 : 0
  role       = aws_iam_role.s3_replication[0].name
  policy_arn = aws_iam_policy.s3_replication[0].arn
}

resource "aws_s3_bucket_replication_configuration" "primary_to_dr" {
  # Turns on cross-region replication from the primary bucket to the DR bucket.
  count  = var.enable_dr_replication ? 1 : 0
  bucket = aws_s3_bucket.primary_dr_test.id
  role   = aws_iam_role.s3_replication[0].arn

  rule {
    id     = "replicate-to-dr"
    status = "Enabled"

    filter {}

    delete_marker_replication {
      status = "Enabled"
    }

    destination {
      bucket        = aws_s3_bucket.dr_test.arn
      storage_class = "STANDARD_IA"
    }
  }

  depends_on = [
    aws_s3_bucket_versioning.primary_dr_test,
    aws_s3_bucket_versioning.dr_test,
  ]
}

# DR-region ECR repository for failover deployments.
resource "aws_ecr_repository" "dr" {
  count    = var.enable_ecr_replication ? 1 : 0
  provider = aws.dr
  name     = var.ecr_repository

  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(var.common_tags, {
    Name   = var.ecr_repository
    Region = var.dr_region
    Role   = "dr"
  })
}

# Registry-level rule that replicates images from the primary region to the DR region.
resource "aws_ecr_replication_configuration" "dr" {
  count = var.enable_ecr_replication ? 1 : 0

  replication_configuration {
    rule {
      destination {
        region      = var.dr_region
        registry_id = data.aws_caller_identity.current.account_id
      }

      repository_filter {
        filter      = var.ecr_repository
        filter_type = "PREFIX_MATCH"
      }
    }
  }

  depends_on = [aws_ecr_repository.dr]
}

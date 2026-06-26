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
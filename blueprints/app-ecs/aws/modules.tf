module "network" {
  source             = "../../../modules/aws/network-ecs"
  name               = var.name
  vpc_cidr           = var.vpc_cidr
  availability_zones = local.azs
  single_nat_gateway = !var.production_mode
  enable_flow_logs   = true
  tags               = local.tags
}
module "registry" {
  log_retention_days = var.production_mode ? 90 : 14
  source             = "../../../modules/aws/registry-ecr"
  name               = var.name
  tags               = local.tags
}
module "domain" {
  source        = "../../../modules/aws/domain-acm-route53"
  enabled       = var.domain_name != "" && var.route53_zone_id != ""
  domain_name   = var.domain_name
  api_subdomain = var.api_subdomain
  zone_id       = var.route53_zone_id
  tags          = local.tags
}
module "frontend" {
  count  = var.frontend_domain_name != "" ? 1 : 0
  source = "../../../modules/aws/frontend-cloudfront"
  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }
  name          = var.name
  domain_name   = var.frontend_domain_name
  zone_id       = var.route53_zone_id
  force_destroy = !var.production_mode
  tags          = local.tags
}
resource "terraform_data" "configuration" {
  lifecycle {
    precondition {
      condition     = !var.production_mode || (var.domain_name != "" && var.route53_zone_id != "" && var.desired_count >= 2 && length(var.alarm_actions) > 0 && can(regex("@sha256:[a-f0-9]{64}$", var.container_image)) && can(regex("^[1-9][0-9]*(:[0-9]+)?$", var.container_user)) && var.readonly_root_filesystem && length(var.health_check_command) >= 2)
      error_message = "Production mode requires TLS, at least two tasks, alarm recipients, a digest-pinned image, an explicit non-root numeric user, read-only root filesystem, and an image-native health command."
    }
    precondition {
      condition     = var.max_capacity >= var.desired_count
      error_message = "Maximum capacity must be at least desired_count."
    }
    precondition {
      condition     = (var.domain_name == "") == (var.route53_zone_id == "") && !strcontains(var.route53_zone_id, "REPLACE_WITH")
      error_message = "Set both domain_name and a real route53_zone_id, or leave both empty for the HTTP smoke test."
    }
    precondition {
      condition     = var.frontend_domain_name == "" || (var.domain_name != "" && var.route53_zone_id != "")
      error_message = "The frontend domain requires the same Route 53 zone and TLS domain configuration as the API."
    }
    precondition {
      condition     = contains(keys(local.fargate_memory), tostring(var.cpu)) && contains(lookup(local.fargate_memory, tostring(var.cpu), []), var.memory)
      error_message = "Select a supported Fargate CPU/memory combination (256-4096 CPU units)."
    }
  }
}
module "compute" {
  depends_on               = [terraform_data.configuration]
  health_check_command     = var.health_check_command
  container_user           = var.container_user
  readonly_root_filesystem = var.readonly_root_filesystem
  container_environment    = var.frontend_domain_name != "" ? { CORS_ORIGINS = "https://${var.frontend_domain_name}" } : {}
  source                   = "../../../modules/aws/compute-ecs"
  name                     = var.name
  region                   = var.region
  container_image          = var.container_image
  container_port           = var.container_port
  health_check_path        = var.health_check_path
  cpu                      = var.cpu
  memory                   = var.memory
  log_group_name           = module.registry.log_group_name
  tags                     = local.tags
}
module "load_balancer" {
  deletion_protection = var.production_mode
  source              = "../../../modules/aws/load-balancer-alb"
  name                = var.name
  vpc_id              = module.network.vpc_id
  public_subnet_ids   = module.network.public_subnet_ids
  private_subnet_ids  = module.network.private_subnet_ids
  cluster_id          = module.compute.cluster_id
  cluster_name        = module.compute.cluster_name
  max_capacity        = var.max_capacity
  alarm_actions       = var.alarm_actions
  task_definition_arn = module.compute.task_definition_arn
  container_port      = var.container_port
  health_check_path   = var.health_check_path
  desired_count       = var.desired_count
  certificate_arn     = module.domain.certificate_arn
  https_enabled       = var.domain_name != "" && var.route53_zone_id != ""
  tags                = local.tags
}
resource "aws_route53_record" "api" {
  count   = var.domain_name != "" && var.route53_zone_id != "" ? 1 : 0
  zone_id = var.route53_zone_id
  name    = "${var.api_subdomain}.${var.domain_name}"
  type    = "A"
  alias {
    name                   = module.load_balancer.dns_name
    zone_id                = module.load_balancer.zone_id
    evaluate_target_health = true
  }
}

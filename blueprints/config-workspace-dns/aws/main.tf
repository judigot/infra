data "aws_route53_zone" "this" {
  name         = var.domain_name
  private_zone = false
}

module "workspace_hosts" {
  source = "../../../modules/aws/dns-cname-records"

  zone_id     = data.aws_route53_zone.this.zone_id
  domain_name = var.domain_name
  names       = var.workspace_cnames
  ttl         = var.ttl
  tags        = var.tags
}

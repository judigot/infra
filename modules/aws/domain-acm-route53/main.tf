resource "aws_acm_certificate" "api" {
  count             = var.enabled ? 1 : 0
  domain_name       = "${var.api_subdomain}.${var.domain_name}"
  validation_method = "DNS"
  lifecycle { create_before_destroy = true }
  tags = var.tags
}
resource "aws_route53_record" "validation" {
  for_each = var.enabled ? {
    for option in aws_acm_certificate.api[0].domain_validation_options : option.domain_name => {
      name   = option.resource_record_name
      type   = option.resource_record_type
      record = option.resource_record_value
    }
  } : {}
  zone_id = var.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.record]
}
resource "aws_acm_certificate_validation" "api" {
  count                   = var.enabled ? 1 : 0
  certificate_arn         = aws_acm_certificate.api[0].arn
  validation_record_fqdns = [for record in aws_route53_record.validation : record.fqdn]
}

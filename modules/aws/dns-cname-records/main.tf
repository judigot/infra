resource "aws_route53_record" "cname" {
  for_each = toset(var.names)

  zone_id = var.zone_id
  name    = "${each.value}.${var.domain_name}"
  type    = "CNAME"
  ttl     = var.ttl
  records = [var.domain_name]
}

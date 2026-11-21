output "fqdns" {
  description = "Fully qualified CNAME names managed by this module."
  value       = [for record in aws_route53_record.cname : trimsuffix(record.fqdn, ".")]
}

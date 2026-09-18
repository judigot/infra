output "hosted_zone_id" {
  description = "Route 53 hosted-zone ID to pass to application environments."
  value       = aws_route53_zone.this.zone_id
}

output "name_servers" {
  description = "Nameservers to configure at the domain registrar."
  value       = aws_route53_zone.this.name_servers
}

output "domain_name" {
  value = aws_route53_zone.this.name
}

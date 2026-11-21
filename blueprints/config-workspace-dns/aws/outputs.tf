output "hosted_zone_id" {
  value = data.aws_route53_zone.this.zone_id
}

output "domain_name" {
  value = trimsuffix(data.aws_route53_zone.this.name, ".")
}

output "workspace_fqdns" {
  description = "Workspace hostnames managed as CNAMEs to the apex."
  value       = module.workspace_hosts.fqdns
}

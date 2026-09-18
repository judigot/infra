output "cluster_name" { value = module.compute.cluster_name }
output "api_repository_url" { value = module.registry.repository_url }
output "api_load_balancer_hostname" { value = module.load_balancer.dns_name }
output "api_url" { value = var.domain_name != "" && var.route53_zone_id != "" ? "https://${var.api_subdomain}.${var.domain_name}" : "http://${module.load_balancer.dns_name}" }

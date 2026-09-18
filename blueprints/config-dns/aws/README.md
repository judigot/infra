# DNS configuration blueprint

Creates the public Route 53 hosted zone for a domain. Run this once per domain,
not once per application environment.

After applying, configure the output `name_servers` at the domain registrar.
Use the `hosted_zone_id` output as `route53_zone_id` in application environment
tfvars files.

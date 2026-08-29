output "public_ip" { value = module.compute.public_ip }
output "db_endpoint" { value = module.database.endpoint }
output "db_port" { value = module.database.port }

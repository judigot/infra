output "dev_ip" {
  value = var.enable_ec2 ? aws_instance.app[0].public_ip : null
}

output "ssh_user" {
  value = var.os == "windows" ? "Administrator" : "ubuntu"
}

output "ssh_command" {
  value = var.enable_ec2 && var.os == "linux" ? "ssh -i ~/.ssh/${var.ssh_key_name} ubuntu@${aws_instance.app[0].public_ip}" : null
}

output "db_endpoint" {
  value = var.create_database ? aws_db_instance.database[0].address : null
}

output "db_port" {
  value = var.create_database ? aws_db_instance.database[0].port : null
}

output "db_username" {
  value = var.create_database ? var.db_username : null
}

output "db_connection_string" {
  value = var.create_database ? "${var.db_engine == "mysql" ? "mysql" : "postgresql"}://${var.db_username}:[YOUR-PASSWORD]@${aws_db_instance.database[0].endpoint}/${var.db_name}" : null
}

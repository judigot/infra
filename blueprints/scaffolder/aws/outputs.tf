output "instance_id" {
  value = aws_instance.scaffolder.id
}

output "public_ip" {
  value = aws_eip.scaffolder.public_ip
}

output "url" {
  value = "https://${var.domain_name}"
}

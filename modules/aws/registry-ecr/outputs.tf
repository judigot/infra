output "repository_url" { value = aws_ecr_repository.api.repository_url }
output "log_group_name" { value = aws_cloudwatch_log_group.api.name }

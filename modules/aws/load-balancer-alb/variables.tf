variable "name" { type = string }
variable "vpc_id" { type = string }
variable "public_subnet_ids" { type = list(string) }
variable "private_subnet_ids" { type = list(string) }
variable "cluster_id" { type = string }
variable "cluster_name" { type = string }
variable "alarm_actions" {
  type    = list(string)
  default = []
}
variable "max_capacity" {
  type    = number
  default = 4
}
variable "task_definition_arn" { type = string }
variable "container_port" { type = number }
variable "health_check_path" { type = string }
variable "desired_count" { type = number }
variable "https_enabled" {
  type    = bool
  default = false
}
variable "certificate_arn" {
  type    = string
  default = ""
}
variable "tags" { type = map(string) }
variable "deletion_protection" {
  type    = bool
  default = false
}

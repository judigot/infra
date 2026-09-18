variable "name" { type = string }
variable "region" { type = string }
variable "container_image" { type = string }
variable "container_port" { type = number }
variable "health_check_path" { type = string }
variable "cpu" { type = number }
variable "memory" { type = number }
variable "log_group_name" { type = string }
variable "tags" { type = map(string) }
variable "health_check_command" {
  type    = list(string)
  default = []
}
variable "container_user" {
  type    = string
  default = ""
}
variable "readonly_root_filesystem" {
  type    = bool
  default = false
}

variable "name" { type = string }
variable "region" { type = string }
variable "instance_type" { type = string }
variable "disk_size" { type = number }
variable "volume_type" { type = string }
variable "ssh_key_name" { type = string }
variable "ssh_public_key" {
  type      = string
  sensitive = true
}
variable "rdp_allowed_cidrs" { type = list(string) }
variable "app_ports" { type = list(number) }

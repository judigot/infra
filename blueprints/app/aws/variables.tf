variable "name" { type = string }
variable "region" { type = string }
variable "instance_type" { type = string }
variable "disk_size" { type = number }
variable "volume_type" { type = string }
variable "custom_ami" { type = string }
variable "ssh_key_name" { type = string }
variable "ssh_public_key" {
  type      = string
  sensitive = true
}
variable "ssh_allowed_cidrs" { type = list(string) }
variable "rdp_allowed_cidrs" {
  type    = list(string)
  default = []
}
variable "app_ports" { type = list(number) }
variable "operating_system" {
  type    = string
  default = "linux"

  validation {
    condition     = contains(["linux", "windows"], var.operating_system)
    error_message = "operating_system must be linux or windows."
  }
}

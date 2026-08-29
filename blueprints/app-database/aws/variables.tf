variable "name" { type = string }
variable "region" { type = string }
variable "instance_type" { type = string }
variable "disk_size" { type = number }
variable "volume_type" { type = string }
variable "custom_ami" {
  type    = string
  default = ""
}
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
variable "db_engine" {
  type    = string
  default = "postgresql"

  validation {
    condition     = contains(["postgresql", "mysql"], var.db_engine)
    error_message = "db_engine must be postgresql or mysql."
  }
}
variable "db_engine_version" { type = string }
variable "db_name" { type = string }
variable "db_username" { type = string }
variable "db_password" {
  type      = string
  sensitive = true
}
variable "db_instance_class" { type = string }
variable "database_publicly_accessible" { type = bool }
variable "database_allowed_cidrs" { type = list(string) }

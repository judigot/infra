variable "name" { type = string }
variable "region" { type = string }
variable "instance_type" { type = string }
variable "disk_size" { type = number }
variable "volume_type" { type = string }
variable "ssh_key_name" { type = string }
variable "ssh_public_key" { type = string sensitive = true }
variable "ssh_allowed_cidrs" { type = list(string) }
variable "app_ports" { type = list(number) }
variable "db_engine" { type = string }
variable "db_engine_version" { type = string }
variable "db_name" { type = string }
variable "db_username" { type = string }
variable "db_password" { type = string sensitive = true }
variable "db_instance_class" { type = string }
variable "database_publicly_accessible" { type = bool }
variable "database_allowed_cidrs" { type = list(string) }

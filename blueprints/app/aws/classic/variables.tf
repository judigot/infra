variable "region" { type = string default = "us-east-1" }
variable "enable_ec2" { type = bool default = false }
variable "create_database" { type = bool default = false }
variable "os" {
  type = string
  default = "linux"
  validation {
    condition = contains(["linux", "windows"], var.os)
    error_message = "os must be linux or windows."
  }
}
variable "instance_type" { type = string default = "c5ad.large" }
variable "disk_size" { type = number default = 20 }
variable "volume_type" { type = string default = "gp3" }
variable "custom_ami" { type = string default = "" }
variable "ssh_key_name" { type = string default = "id_ed25519" }
variable "ssh_public_key" { type = string sensitive = true }
variable "ssh_allowed_cidrs" { type = list(string) default = [] }
variable "rdp_allowed_cidrs" { type = list(string) default = [] }
variable "app_ports" { type = list(number) default = [3000, 5000, 8000, 8001, 8080, 9000, 9200] }
variable "app_allowed_cidrs" { type = list(string) default = ["0.0.0.0/0"] }
variable "db_engine" {
  type = string
  default = "postgresql"
  validation {
    condition = contains(["postgresql", "mysql"], var.db_engine)
    error_message = "db_engine must be postgresql or mysql."
  }
}
variable "db_engine_version" { type = string default = "" }
variable "db_name" { type = string default = "app_db" }
variable "db_username" { type = string default = "app" }
variable "db_password" { type = string sensitive = true default = "" }
variable "db_instance_class" { type = string default = "db.t4g.micro" }
variable "database_publicly_accessible" { type = bool default = false }
variable "database_allowed_cidrs" { type = list(string) default = [] }

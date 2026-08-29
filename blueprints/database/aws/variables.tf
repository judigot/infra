variable "name" { type = string }
variable "region" { type = string }
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

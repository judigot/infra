variable "name" { type = string }
variable "vpc_cidr" { type = string }
variable "availability_zones" { type = list(string) }
variable "tags" { type = map(string) }
variable "single_nat_gateway" {
  type    = bool
  default = true
}
variable "enable_flow_logs" {
  type    = bool
  default = true
}
variable "flow_log_retention_days" {
  type    = number
  default = 30
}

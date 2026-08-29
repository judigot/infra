variable "name" { type = string default = "app" }
variable "region" { type = string default = "us-east-1" }
variable "instance_type" { type = string default = "t3.small" }
variable "disk_size" { type = number default = 20 }
variable "volume_type" { type = string default = "gp3" }
variable "custom_ami" { type = string default = "" }
variable "ssh_key_name" { type = string default = "id_ed25519" }
variable "ssh_public_key" { type = string sensitive = true }
variable "ssh_allowed_cidrs" { type = list(string) default = [] }
variable "app_ports" { type = list(number) default = [80, 443, 3000, 5000, 8000, 8001, 8080, 9000, 9200] }

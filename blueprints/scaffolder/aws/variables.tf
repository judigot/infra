variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "client_name" {
  type = string
}

variable "environment" {
  type    = string
  default = "production"
}

variable "domain_name" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "m7i.xlarge"
}

variable "ssh_public_key" {
  type      = string
  sensitive = true
}

variable "ssh_allowed_cidrs" {
  type    = list(string)
  default = []
}

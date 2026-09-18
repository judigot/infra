variable "aws_profile" { type = string }
variable "region" { type = string }

variable "domain_name" {
  type = string
  validation {
    condition     = can(regex("^[a-z0-9](?:[a-z0-9.-]*[a-z0-9])?$", var.domain_name)) && !strcontains(var.domain_name, "..")
    error_message = "Provide a valid public DNS name without a trailing dot."
  }
}

variable "tags" {
  type    = map(string)
  default = {}
}

resource "aws_route53_zone" "this" {
  name = var.domain_name

  tags = merge(var.tags, {
    ManagedBy = "terraform"
    Purpose   = "authoritative-dns"
  })
}

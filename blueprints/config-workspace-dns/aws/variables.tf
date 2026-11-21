variable "aws_profile" { type = string }
variable "region" { type = string }

variable "domain_name" {
  type = string
  validation {
    condition     = can(regex("^[a-z0-9](?:[a-z0-9.-]*[a-z0-9])?$", var.domain_name)) && !strcontains(var.domain_name, "..")
    error_message = "Provide a valid public DNS name without a trailing dot."
  }
}

variable "workspace_cnames" {
  type        = list(string)
  description = "Workspace host labels created as CNAMEs to the apex domain."
  default     = ["dev"]
}

variable "ttl" {
  type    = number
  default = 60
}

variable "tags" {
  type    = map(string)
  default = {}
}

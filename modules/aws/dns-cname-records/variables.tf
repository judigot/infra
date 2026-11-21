variable "zone_id" {
  type        = string
  description = "Route 53 hosted zone ID."
}

variable "domain_name" {
  type        = string
  description = "Apex domain without a trailing dot, used as the CNAME target."
  validation {
    condition     = can(regex("^[a-z0-9](?:[a-z0-9.-]*[a-z0-9])?$", var.domain_name)) && !strcontains(var.domain_name, "..")
    error_message = "Provide a valid public DNS name without a trailing dot."
  }
}

variable "names" {
  type        = list(string)
  description = "Subdomain labels to create as CNAMEs to the apex, for example [\"dev\", \"db\"]."
  validation {
    condition = alltrue([
      for name in var.names : can(regex("^[a-z0-9](?:[a-z0-9-]*[a-z0-9])?$", name))
    ])
    error_message = "Each name must be a DNS label."
  }
}

variable "ttl" {
  type    = number
  default = 60
}

variable "tags" {
  type    = map(string)
  default = {}
}

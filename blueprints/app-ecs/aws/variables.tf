variable "name" {
  type = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,27}[a-z0-9]$", var.name))
    error_message = "Use 2-29 lowercase letters, digits, or hyphens; start with a letter and end with a letter or digit."
  }
}
variable "aws_profile" { type = string }
variable "region" { type = string }
variable "vpc_cidr" {
  type    = string
  default = "10.42.0.0/16"
  validation {
    condition     = can(cidrnetmask(var.vpc_cidr)) && try(tonumber(split("/", var.vpc_cidr)[1]) >= 16 && tonumber(split("/", var.vpc_cidr)[1]) <= 20, false)
    error_message = "Provide an IPv4 VPC CIDR from /16 through /20; this module adds eight subnet bits."
  }
}
variable "availability_zones" {
  type    = list(string)
  default = []
  validation {
    condition     = length(var.availability_zones) == 0 || (length(var.availability_zones) >= 2 && length(var.availability_zones) <= 3 && length(distinct(var.availability_zones)) == length(var.availability_zones))
    error_message = "Supply two or three distinct availability zones, or leave empty for automatic selection."
  }
}
variable "container_image" {
  type    = string
  default = "public.ecr.aws/docker/library/nginx:stable-alpine"
  validation {
    condition     = length(var.container_image) > 0 && !strcontains(var.container_image, "REPLACE_WITH")
    error_message = "Provide an actual container image reference, not a placeholder."
  }
}
variable "container_port" {
  type    = number
  default = 80
  validation {
    condition     = var.container_port >= 1 && var.container_port <= 65535 && floor(var.container_port) == var.container_port
    error_message = "Container port must be an integer from 1 to 65535."
  }
}
variable "desired_count" {
  type    = number
  default = 1
  validation {
    condition     = var.desired_count >= 1 && floor(var.desired_count) == var.desired_count
    error_message = "Desired count must be a positive integer."
  }
}
variable "cpu" {
  type    = number
  default = 256
}
variable "max_capacity" {
  type    = number
  default = 1
  validation {
    condition     = var.max_capacity >= 1 && floor(var.max_capacity) == var.max_capacity
    error_message = "Maximum capacity must be a positive integer."
  }
}
variable "alarm_actions" {
  type        = list(string)
  default     = []
  description = "SNS topic ARNs to notify. Empty means alarms have no notification recipients."
}
variable "memory" {
  type    = number
  default = 512
}
variable "health_check_path" {
  type    = string
  default = "/"
  validation {
    condition     = can(regex("^/[a-zA-Z0-9/_-]*$", var.health_check_path))
    error_message = "Health check path must start with / and contain only letters, digits, slash, underscore, or hyphen."
  }
}
variable "domain_name" {
  type    = string
  default = ""
}
variable "route53_zone_id" {
  type    = string
  default = ""
}
variable "api_subdomain" {
  type    = string
  default = "api"
}

variable "production_mode" {
  type        = bool
  default     = false
  description = "Enforce baseline production inputs. This does not establish deployment readiness."
}
variable "health_check_command" {
  type    = list(string)
  default = []
  validation {
    condition     = length(var.health_check_command) == 0 || (length(var.health_check_command) >= 2 && contains(["CMD", "CMD-SHELL"], try(var.health_check_command[0], "")))
    error_message = "Supply an ECS CMD or CMD-SHELL health check, or leave empty for the smoke-test wget check."
  }
}
variable "container_user" {
  type    = string
  default = ""
}
variable "readonly_root_filesystem" {
  type    = bool
  default = false
}

variable "tags" {
  type    = map(string)
  default = {}
}

locals {
  fargate_memory = {
    "256"  = [512, 1024, 2048]
    "512"  = [1024, 2048, 3072, 4096]
    "1024" = range(2048, 8193, 1024)
    "2048" = range(4096, 16385, 1024)
    "4096" = range(8192, 30721, 1024)
  }
  azs  = length(var.availability_zones) > 0 ? var.availability_zones : slice(data.aws_availability_zones.available.names, 0, 2)
  tags = merge(var.tags, { Application = var.name, ManagedBy = "terraform" })
}

data "aws_availability_zones" "available" { state = "available" }

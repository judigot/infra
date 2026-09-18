variable "name" { type = string }
variable "domain_name" { type = string }
variable "zone_id" { type = string }
variable "force_destroy" {
  type        = bool
  default     = false
  description = "Delete all frontend object versions with the bucket. Intended only for disposable environments."
}
variable "tags" {
  type    = map(string)
  default = {}
}

variable "name" { type = string }
variable "vpc_id" { type = string }
variable "subnet_ids" { type = list(string) }
variable "app_security_group_id" { type = string default = "" }
variable "engine" { type = string default = "postgresql" }
variable "engine_version" { type = string default = "" }
variable "db_name" { type = string default = "app_db" }
variable "username" { type = string default = "app" }
variable "password" { type = string sensitive = true }
variable "instance_class" { type = string default = "db.t4g.micro" }
variable "publicly_accessible" { type = bool default = false }
variable "allowed_cidrs" { type = list(string) default = [] }

locals {
  engine_name    = var.engine == "mysql" ? "mysql" : "postgres"
  engine_version = var.engine_version != "" ? var.engine_version : (var.engine == "mysql" ? "8.0" : "16.3")
  port           = var.engine == "mysql" ? 3306 : 5432
}

resource "aws_db_subnet_group" "this" { name_prefix = "${var.name}-" subnet_ids = var.subnet_ids }
resource "aws_security_group" "this" {
  name_prefix = "${var.name}-"
  vpc_id      = var.vpc_id
  dynamic "ingress" {
    for_each = length(var.allowed_cidrs) > 0 ? [1] : []
    content { from_port = local.port to_port = local.port protocol = "tcp" cidr_blocks = var.allowed_cidrs }
  }
  dynamic "ingress" {
    for_each = var.app_security_group_id != "" ? [1] : []
    content { from_port = local.port to_port = local.port protocol = "tcp" security_groups = [var.app_security_group_id] }
  }
  egress { from_port = 0 to_port = 0 protocol = "-1" cidr_blocks = ["0.0.0.0/0"] }
}
resource "aws_db_instance" "this" {
  identifier_prefix       = "${var.name}-"
  engine                  = local.engine_name
  engine_version          = local.engine_version
  instance_class          = var.instance_class
  allocated_storage       = 20
  max_allocated_storage   = 100
  storage_type            = "gp3"
  storage_encrypted       = true
  db_name                 = var.db_name
  username                = var.username
  password                = var.password
  db_subnet_group_name    = aws_db_subnet_group.this.name
  vpc_security_group_ids  = [aws_security_group.this.id]
  publicly_accessible     = var.publicly_accessible
  backup_retention_period = 7
  skip_final_snapshot     = true
}
output "endpoint" { value = aws_db_instance.this.address }
output "port" { value = aws_db_instance.this.port }

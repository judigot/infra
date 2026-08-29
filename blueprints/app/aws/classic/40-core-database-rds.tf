locals {
  db_engine_name    = var.db_engine == "mysql" ? "mysql" : "postgres"
  db_engine_version = var.db_engine_version != "" ? var.db_engine_version : (var.db_engine == "mysql" ? "8.0" : "16.3")
}

resource "aws_db_subnet_group" "main" {
  count       = var.create_database ? 1 : 0
  name_prefix = "classic-db-"
  subnet_ids  = aws_subnet.public[*].id
}

resource "aws_security_group" "database" {
  count       = var.create_database ? 1 : 0
  name_prefix = "classic-db-"
  vpc_id      = aws_vpc.main[0].id

  dynamic "ingress" {
    for_each = length(var.database_allowed_cidrs) > 0 ? [1] : []
    content {
      from_port   = local.db_port
      to_port     = local.db_port
      protocol    = "tcp"
      cidr_blocks = var.database_allowed_cidrs
    }
  }

  dynamic "ingress" {
    for_each = var.enable_ec2 ? [1] : []
    content {
      from_port       = local.db_port
      to_port         = local.db_port
      protocol        = "tcp"
      security_groups = [aws_security_group.app[0].id]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "database" {
  count                   = var.create_database ? 1 : 0
  identifier_prefix       = "classic-${var.db_engine}-"
  engine                  = local.db_engine_name
  engine_version          = local.db_engine_version
  instance_class          = var.db_instance_class
  allocated_storage       = 20
  max_allocated_storage   = 100
  storage_type            = "gp3"
  storage_encrypted       = true
  db_name                 = var.db_name
  username                = var.db_username
  password                = var.db_password
  db_subnet_group_name    = aws_db_subnet_group.main[0].name
  vpc_security_group_ids  = [aws_security_group.database[0].id]
  publicly_accessible     = var.database_publicly_accessible
  backup_retention_period = 7
  skip_final_snapshot     = true
  deletion_protection     = false

  lifecycle {
    precondition {
      condition     = var.db_password != ""
      error_message = "db_password must be provided when create_database=true."
    }
  }
}

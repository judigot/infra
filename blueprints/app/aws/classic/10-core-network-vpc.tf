locals {
  create_network = var.enable_ec2 || var.create_database
  db_port        = var.db_engine == "mysql" ? 3306 : 5432
}

resource "aws_vpc" "main" {
  count                = local.create_network ? 1 : 0
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "classic-app" }
}

resource "aws_internet_gateway" "main" {
  count  = local.create_network ? 1 : 0
  vpc_id = aws_vpc.main[0].id
}

resource "aws_route_table" "public" {
  count  = local.create_network ? 1 : 0
  vpc_id = aws_vpc.main[0].id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main[0].id
  }
}

resource "aws_subnet" "public" {
  count                   = local.create_network ? 2 : 0
  vpc_id                  = aws_vpc.main[0].id
  cidr_block              = cidrsubnet(aws_vpc.main[0].cidr_block, 8, count.index + 1)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = { Name = "classic-public-${count.index + 1}" }
}

resource "aws_route_table_association" "public" {
  count          = local.create_network ? 2 : 0
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_security_group" "app" {
  count       = var.enable_ec2 ? 1 : 0
  name_prefix = "classic-app-"
  description = "Classic app server ingress"
  vpc_id      = aws_vpc.main[0].id

  dynamic "ingress" {
    for_each = length(var.ssh_allowed_cidrs) == 0 ? [] : [1]
    content {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = var.ssh_allowed_cidrs
    }
  }

  dynamic "ingress" {
    for_each = var.os == "windows" && length(var.rdp_allowed_cidrs) > 0 ? [1] : []
    content {
      from_port   = 3389
      to_port     = 3389
      protocol    = "tcp"
      cidr_blocks = var.rdp_allowed_cidrs
    }
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  dynamic "ingress" {
    for_each = toset(var.app_ports)
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = var.app_allowed_cidrs
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

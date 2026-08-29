terraform {
  required_version = ">= 1.9.0"

  backend "s3" {}

  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_route53_zone" "domain" {
  name         = var.domain_name
  private_zone = false
}

resource "aws_iam_role" "scaffolder_ssm" {
  name = "scaffolder-${var.environment}-ssm"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "scaffolder_ssm_core" {
  role       = aws_iam_role.scaffolder_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "scaffolder" {
  name = "scaffolder-${var.environment}-ssm"
  role = aws_iam_role.scaffolder_ssm.name
}

resource "aws_key_pair" "owner" {
  key_name   = "scaffolder-${var.environment}-owner"
  public_key = var.ssh_public_key
}

resource "aws_security_group" "web" {
  name_prefix = "scaffolder-web-"
  description = "Public HTTP/HTTPS and optional owner SSH for Scaffolder"

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
    for_each = var.ssh_allowed_cidrs
    content {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "scaffolder" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.web.id]
  key_name                    = aws_key_pair.owner.key_name
  iam_instance_profile        = aws_iam_instance_profile.scaffolder.name

  root_block_device {
    encrypted   = true
    volume_type = "gp3"
    volume_size = 20
  }

  tags = {
    Name        = "scaffolder-${var.environment}"
    Application = "scaffolder"
    Environment = var.environment
    Client      = var.client_name
  }
}

resource "aws_eip" "scaffolder" {
  domain   = "vpc"
  instance = aws_instance.scaffolder.id

  tags = {
    Name = "scaffolder-${var.environment}"
  }
}

resource "aws_route53_record" "root" {
  zone_id         = data.aws_route53_zone.domain.zone_id
  name            = var.domain_name
  type            = "A"
  ttl             = 60
  records         = [aws_eip.scaffolder.public_ip]
  allow_overwrite = true
}

resource "aws_route53_record" "www" {
  zone_id         = data.aws_route53_zone.domain.zone_id
  name            = "www.${var.domain_name}"
  type            = "CNAME"
  ttl             = 60
  records         = [var.domain_name]
  allow_overwrite = true
}

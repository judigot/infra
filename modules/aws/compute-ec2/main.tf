variable "name" { type = string }
variable "vpc_id" { type = string }
variable "subnet_id" { type = string }

variable "os" {
  type    = string
  default = "linux"
}

variable "instance_type" {
  type    = string
  default = "t3.small"
}

variable "disk_size" {
  type    = number
  default = 20
}

variable "volume_type" {
  type    = string
  default = "gp3"
}

variable "custom_ami" {
  type    = string
  default = ""
}

variable "ssh_key_name" {
  type    = string
  default = "id_ed25519"
}

variable "ssh_public_key" {
  type      = string
  sensitive = true
}

variable "ssh_allowed_cidrs" {
  type    = list(string)
  default = []
}

variable "rdp_allowed_cidrs" {
  type    = list(string)
  default = []
}

variable "app_ports" {
  type    = list(number)
  default = [80, 443, 3000, 5000, 8000, 8001, 8080, 9000, 9200]
}

variable "app_allowed_cidrs" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

data "aws_ami" "ubuntu" {
  count       = var.os == "linux" && var.custom_ami == "" ? 1 : 0
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

data "aws_ami" "windows" {
  count       = var.os == "windows" && var.custom_ami == "" ? 1 : 0
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2025-English-Full-Base-*"]
  }
}

resource "aws_key_pair" "this" {
  key_name   = var.ssh_key_name
  public_key = var.ssh_public_key
}

resource "aws_security_group" "this" {
  name_prefix = "${var.name}-"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = length(var.ssh_allowed_cidrs) > 0 ? [1] : []
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

resource "aws_instance" "this" {
  ami = var.custom_ami != "" ? var.custom_ami : (
    var.os == "windows" ? data.aws_ami.windows[0].id : data.aws_ami.ubuntu[0].id
  )
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.this.id]
  key_name                    = aws_key_pair.this.key_name
  associate_public_ip_address = true

  root_block_device {
    volume_type           = var.volume_type
    volume_size           = var.disk_size
    delete_on_termination = true
    encrypted             = true
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = {
    Name = var.name
  }
}

output "instance_id" { value = aws_instance.this.id }
output "public_ip" { value = aws_instance.this.public_ip }
output "security_group_id" { value = aws_security_group.this.id }
output "ssh_user" { value = var.os == "windows" ? "Administrator" : "ubuntu" }

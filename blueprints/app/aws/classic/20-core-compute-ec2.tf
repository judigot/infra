data "aws_ami" "ubuntu" {
  count       = var.enable_ec2 && var.os == "linux" && var.custom_ami == "" ? 1 : 0
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
  count       = var.enable_ec2 && var.os == "windows" && var.custom_ami == "" ? 1 : 0
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2025-English-Full-Base-*"]
  }
}

resource "aws_key_pair" "owner" {
  count      = var.enable_ec2 ? 1 : 0
  key_name   = var.ssh_key_name
  public_key = var.ssh_public_key
}

resource "aws_instance" "app" {
  count = var.enable_ec2 ? 1 : 0
  ami = var.custom_ami != "" ? var.custom_ami : (
    var.os == "windows" ? data.aws_ami.windows[0].id : data.aws_ami.ubuntu[0].id
  )
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.app[0].id]
  key_name                    = aws_key_pair.owner[0].key_name
  associate_public_ip_address = true

  root_block_device {
    volume_type           = var.volume_type
    volume_size           = var.disk_size
    delete_on_termination = true
    encrypted             = true
  }

  user_data = var.os == "linux" ? templatefile("${path.module}/cloud-init.yaml.tftpl", {}) : null

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = {
    Name = "classic-app-server"
  }
}

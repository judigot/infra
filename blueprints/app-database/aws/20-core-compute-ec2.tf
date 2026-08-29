module "compute" {
  source            = "../../../modules/aws/compute-ec2"
  name              = var.name
  vpc_id            = module.network.vpc_id
  subnet_id         = module.network.public_subnet_ids[0]
  os                = var.operating_system
  instance_type     = var.instance_type
  disk_size         = var.disk_size
  volume_type       = var.volume_type
  custom_ami        = var.custom_ami
  ssh_key_name      = var.ssh_key_name
  ssh_public_key    = var.ssh_public_key
  ssh_allowed_cidrs = var.ssh_allowed_cidrs
  rdp_allowed_cidrs = var.rdp_allowed_cidrs
  app_ports         = var.app_ports
}

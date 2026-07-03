module "network" {
  source = "./modules/network"

  project            = var.project
  vpc_cidr           = var.vpc_cidr
  public_subnet_cidr = var.public_subnet_cidr
  availability_zone  = var.availability_zone
}

module "security_group" {
  source = "./modules/security_group"

  project          = var.project
  vpc_id           = module.network.vpc_id
  allowed_ssh_cidr = var.allowed_ssh_cidr
}

module "compute" {
  source = "./modules/compute"

  project                     = var.project
  public_subnet_id            = module.network.public_subnet_id
  security_group_id           = module.security_group.security_group_id
  ami_id                      = var.ami_id
  control_plane_instance_type = var.control_plane_instance_type
  worker_instance_type        = var.worker_instance_type
  worker_count                = var.worker_count
  key_pair_name               = var.key_pair_name
}

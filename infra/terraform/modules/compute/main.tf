variable "project"                     { type = string }
variable "public_subnet_id"            { type = string }
variable "security_group_id"           { type = string }
variable "ami_id"                      { type = string }
variable "control_plane_instance_type" { type = string }
variable "worker_instance_type"        { type = string }
variable "worker_count"                { type = number }
variable "key_pair_name"               { type = string }

resource "aws_instance" "control_plane" {
  ami                    = var.ami_id
  instance_type          = var.control_plane_instance_type
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [var.security_group_id]
  key_name               = var.key_pair_name

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name = "${var.project}-control-plane"
    Role = "control-plane"
  }
}

resource "aws_instance" "workers" {
  count = var.worker_count

  ami                    = var.ami_id
  instance_type          = var.worker_instance_type
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [var.security_group_id]
  key_name               = var.key_pair_name

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name = "${var.project}-worker-${count.index + 1}"
    Role = "worker"
  }
}

output "control_plane_public_ip"  { value = aws_instance.control_plane.public_ip }
output "control_plane_private_ip" { value = aws_instance.control_plane.private_ip }
output "worker_public_ips"        { value = aws_instance.workers[*].public_ip }
output "worker_private_ips"       { value = aws_instance.workers[*].private_ip }

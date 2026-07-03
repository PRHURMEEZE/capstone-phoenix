variable "project"          { type = string }
variable "vpc_id"           { type = string }
variable "allowed_ssh_cidr" { type = string }

resource "aws_security_group" "nodes" {
  name        = "${var.project}-nodes-sg"
  description = "k3s cluster nodes - least-privilege"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH from operator only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "NodePort range"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "k3s API - intra-cluster only"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    self        = true
  }

  ingress {
    description = "kubelet - intra-cluster only"
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    self        = true
  }

  ingress {
    description = "WireGuard overlay"
    from_port   = 51820
    to_port     = 51820
    protocol    = "udp"
    self        = true
  }

  egress {
    description = "All outbound allowed"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project}-nodes-sg" }
}

output "security_group_id" { value = aws_security_group.nodes.id }

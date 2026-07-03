variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "eu-north-1"
}

variable "project" {
  description = "Project name — used as a prefix on all resource names"
  type        = string
  default     = "capstone-phoenix"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "availability_zone" {
  description = "AZ to deploy into"
  type        = string
  default     = "eu-north-1a"
}

variable "allowed_ssh_cidr" {
  description = "Your public IP in CIDR notation — SSH restricted to this only"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for Ubuntu 22.04 LTS in eu-north-1"
  type        = string
}

variable "control_plane_instance_type" {
  description = "Instance type for the k3s control-plane node"
  type        = string
  default     = "t3.medium"
}

variable "worker_instance_type" {
  description = "Instance type for k3s worker nodes"
  type        = string
  default     = "t3.small"
}

variable "worker_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 2
}

variable "key_pair_name" {
  description = "Name of your AWS key pair for SSH access"
  type        = string
}

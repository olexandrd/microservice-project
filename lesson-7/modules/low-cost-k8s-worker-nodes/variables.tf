variable "name" { type = string }
variable "vpc_id" { type = string }
variable "subnet_id" { type = list(string) }
variable "ami" { type = string }
variable "instance_type" { default = "t4g.medium" }
variable "worker_count" { default = 2 }
variable "vpc_cidr_block" {
  description = "CIDR блок для VPC"
  type        = string
}

variable "kubeadm_token_ssm_name" {
  type = string
}
variable "ca_hash_ssm_name" {
  type = string
}
variable "region" {
  type = string
}
variable "master_private_ip" {
  type = string
}

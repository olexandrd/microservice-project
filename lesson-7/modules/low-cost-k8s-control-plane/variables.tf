variable "name" { type = string }
variable "vpc_id" { type = string }
variable "subnet_id" { type = string }
variable "instance_type" { default = "t4g.large" }
variable "pod_network_cidr" { default = "10.244.0.0/16" }
variable "ami" { type = string }
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

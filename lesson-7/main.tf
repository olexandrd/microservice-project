provider "aws" {
  region = var.region
}

data "aws_ami" "k8s_ubuntu_arm64" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-arm64-server-*"]
  }
}

# module "s3_backend" {
#   source      = "./modules/s3-backend"
#   bucket_name = var.bucket_name
#   table_name  = var.table_name
# }

module "vpc" {
  source             = "./modules/vpc"
  vpc_cidr_block     = "10.0.0.0/16"
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets    = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  availability_zones = ["us-east-2a", "us-east-2b", "us-east-2c"]
  vpc_name           = "lesson-5-vpc"
  name               = var.name
}

module "ssm" {
  source         = "./modules/ssm-parameters"
  token_length   = 23
  token_ssm_name = "/k8s/kubeadm_token"
  hash_ssm_name  = "/k8s/ca_cert_hash"
}

module "ecr" {
  source       = "./modules/ecr"
  ecr_name     = "lesson-5-ecr"
  scan_on_push = true
}

# module "eks" {
#   source        = "./modules/eks"
#   cluster_name  = "eks-cluster-demo"
#   subnet_ids    = module.vpc.public_subnets
#   instance_type = "t2.micro"
#   desired_size  = 1
#   max_size      = 2
#   min_size      = 1
# }

module "k8s_control_plane" {
  source                 = "./modules/low-cost-k8s-control-plane"
  name                   = var.name
  vpc_id                 = module.vpc.vpc_id
  subnet_id              = module.vpc.public_subnets[0]
  ami                    = data.aws_ami.k8s_ubuntu_arm64.id
  vpc_cidr_block         = module.vpc.vpc_cidr_block
  pod_network_cidr       = "10.0.4.0/22"
  kubeadm_token_ssm_name = module.ssm.token_ssm_name
  ca_hash_ssm_name       = module.ssm.hash_ssm_name
  region                 = var.region
  depends_on = [
    module.vpc.nat_instance_id,
    module.ssm
  ]
}

module "k8s_worker_nodes" {
  source                 = "./modules/low-cost-k8s-worker-nodes"
  name                   = var.name
  vpc_id                 = module.vpc.vpc_id
  subnet_id              = module.vpc.private_subnets[0]
  ami                    = data.aws_ami.k8s_ubuntu_arm64.id
  vpc_cidr_block         = module.vpc.vpc_cidr_block
  worker_count           = 2
  kubeadm_token_ssm_name = module.ssm.token_ssm_name
  ca_hash_ssm_name       = module.ssm.hash_ssm_name
  master_private_ip      = module.k8s_control_plane.control_plane_private_ip
  region                 = var.region
  depends_on = [
    module.vpc.nat_instance_id,
    module.k8s_control_plane.control_plane_private_ip
  ]
}

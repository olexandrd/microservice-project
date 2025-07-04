provider "aws" {
  region = var.region
}

data "aws_ssm_parameter" "al2_arm64" {
  name = "/aws/service/eks/optimized-ami/1.32/amazon-linux-2023/arm64/standard/recommended/image_id"
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
  vpc_name           = "lesson-7-vpc"
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
  ecr_name     = "lesson-7-ecr"
  scan_on_push = true
}

module "eks" {
  source        = "./modules/eks"
  cluster_name  = "eks-cluster-demo"
  subnet_ids    = module.vpc.private_subnets
  instance_type = "t2.small"
  desired_size  = 1
  max_size      = 2
  min_size      = 1
}




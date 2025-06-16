provider "aws" {
  region = var.region
}

module "s3_backend" {
  source      = "./modules/s3-backend" # Шлях до модуля
  bucket_name = var.bucket_name        # Ім'я S3-бакета
  table_name  = var.table_name         # Ім'я DynamoDB
}

module "vpc" {
  source             = "./modules/vpc"
  vpc_cidr_block     = "10.0.0.0/16"
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets    = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  availability_zones = ["us-east-2a", "us-east-2b", "us-east-2c"]
  vpc_name           = "lesson-5-vpc"
}

# module "ecr" {
#   source       = "./modules/ecr"
#   ecr_name     = "lesson-5-ecr"
#   scan_on_push = true
# }

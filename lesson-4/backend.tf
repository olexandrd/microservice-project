terraform {
  backend "s3" {
    bucket         = "terraform-state-bucket-0011111-olexandr"
    key            = "terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

variable "bucket_name" {
  description = "The name of the S3 bucket for Terraform state"
  type        = string
  default     = "terraform-state-bucket-0011113-olexandr"

}

variable "table_name" {
  description = "The name of the DynamoDB table for Terraform locks"
  type        = string
  default     = "terraform-locks"
}

variable "region" {
  description = "The AWS region for the S3 bucket and DynamoDB table"
  type        = string
  default     = "us-east-2"
}

variable "name" {
  description = "The name of the project"
  type        = string
  default     = "django-app"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  default     = "example-eks-cluster"
}

variable "github_username" {
  description = "GitHub username for Jenkins"
  type        = string
}

variable "github_token" {
  description = "GitHub token for Jenkins"
  type        = string
  sensitive   = true
}

variable "github_repo_url" {
  description = "GitHub repository URL for Jenkins"
  type        = string
}

variable "github_branch" {
  description = "GitHub branch for Jenkins"
  type        = string
}

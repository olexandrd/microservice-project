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

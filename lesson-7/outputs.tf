# output "s3_bucket_name" {
#   description = "Назва S3-бакета для стейтів"
#   value       = module.s3_backend.s3_bucket_name
# }

# output "dynamodb_table_name" {
#   description = "Назва таблиці DynamoDB для блокування стейтів"
#   value       = module.s3_backend.dynamodb_table_name
# }


output "ecr_url" {
  description = "ECR repo URL"
  value       = module.ecr.ecr_url
}




output "eks_cluster_endpoint" {
  description = "EKS API endpoint for connecting to the cluster"
  value       = module.eks.eks_cluster_endpoint
}

output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.eks_cluster_name
}

output "eks_node_role_arn" {
  description = "IAM role ARN for EKS Worker Nodes"
  value       = module.eks.eks_node_role_arn
}

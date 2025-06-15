output "s3_bucket_name" {
  description = "Назва S3-бакета для стейтів"
  value       = s3_backend.s3_bucket_name
}

output "dynamodb_table_name" {
  description = "Назва таблиці DynamoDB для блокування стейтів"
  value       = s3_backend.dynamodb_table_name
}


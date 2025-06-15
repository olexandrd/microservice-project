module "s3_backend" {
  source      = "./modules/s3-backend" # Шлях до модуля
  bucket_name = var.bucket_name        # Ім'я S3-бакета
  table_name  = var.table_name         # Ім'я DynamoDB
}

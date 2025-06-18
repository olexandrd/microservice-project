variable "vpc_cidr_block" {
  description = "CIDR блок для VPC"
  type        = string
}

variable "public_subnets" {
  description = "Список CIDR блоків для публічних підмереж"
  type        = list(string)
}

variable "private_subnets" {
  description = "Список CIDR блоків для приватних підмереж"
  type        = list(string)
}

variable "availability_zones" {
  description = "Список зон доступності для підмереж"
  type        = list(string)
}

variable "vpc_name" {
  description = "Ім'я VPC"
  type        = string
}

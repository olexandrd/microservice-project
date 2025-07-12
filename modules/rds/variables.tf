variable "name" {
  description = "Назва інстансу або кластера"
  type        = string
}

variable "engine" {
  type    = string
  default = "postgres"
}
variable "engine_cluster" {
  type    = string
  default = "aurora-postgresql"
}
variable "aurora_replica_count" {
  type    = number
  default = 1
}

variable "aurora_instance_count" {
  type    = number
  default = 2 # 1 primary + 1 replica
}
variable "engine_version" {
  type    = string
  default = "14.7"
}

variable "instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "allocated_storage" {
  type    = number
  default = 20
}

variable "db_name" {
  type = string
}

variable "username" {
  type = string
}

variable "password" {
  type      = string
  sensitive = true
}

variable "vpc_id" {
  type = string
}

variable "subnet_private_ids" {
  type = list(string)
}

variable "subnet_public_ids" {
  type = list(string)
}

variable "publicly_accessible" {
  type    = bool
  default = false
}

variable "multi_az" {
  type    = bool
  default = false
}

variable "parameters" {
  type    = map(string)
  default = {}
}

variable "use_aurora" {
  type    = bool
  default = false
}

variable "backup_retention_period" {
  type    = string
  default = ""
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "parameter_group_family_aurora" {
  type    = string
  default = "aurora-postgresql15"
}
variable "engine_version_cluster" {
  type    = string
  default = "15.3"
}
variable "parameter_group_family_rds" {
  type    = string
  default = "postgres15"
}

variable "vpc_cidr_block" {
  description = "CIDR блок для VPC"
  type        = string
}

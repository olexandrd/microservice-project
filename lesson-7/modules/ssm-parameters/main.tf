resource "random_password" "kubeadm_token" {
  length  = var.token_length
  special = false
  upper   = false
}

locals {
  raw   = random_password.kubeadm_token.result
  token = "${substr(local.raw, 0, 6)}.${substr(local.raw, 6, 16)}"
}

resource "aws_ssm_parameter" "kubeadm_token" {
  name  = var.token_ssm_name
  type  = "String"
  value = local.token
}


resource "aws_ssm_parameter" "ca_cert_hash" {
  name      = var.hash_ssm_name
  type      = "String"
  value     = "pending"
  overwrite = true
}

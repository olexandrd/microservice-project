variable "token_length" {
  type    = number
  default = 23
}

variable "token_ssm_name" {
  type    = string
  default = "/k8s/kubeadm_token"
}

variable "hash_ssm_name" {
  type    = string
  default = "/k8s/ca_cert_hash"
}

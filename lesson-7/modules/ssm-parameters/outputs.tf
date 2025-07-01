output "kubeadm_token" {
  value = aws_ssm_parameter.kubeadm_token.value
}

output "ca_cert_hash_name" {
  value = aws_ssm_parameter.ca_cert_hash.name
}

output "token_ssm_name" {
  value = aws_ssm_parameter.kubeadm_token.name
}
output "hash_ssm_name" {
  value = aws_ssm_parameter.ca_cert_hash.name
}

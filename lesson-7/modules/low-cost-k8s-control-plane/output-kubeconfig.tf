resource "time_sleep" "wait_for_ssm" {
  depends_on      = [aws_instance.control_plane]
  create_duration = "180s"
}

data "aws_ssm_parameter" "kubeconfig" {
  name            = "/k8s/admin.conf"
  with_decryption = true
  depends_on      = [time_sleep.wait_for_ssm]
}

output "kubeconfig" {
  value     = data.aws_ssm_parameter.kubeconfig.value
  sensitive = true
}

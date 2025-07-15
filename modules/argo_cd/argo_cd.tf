resource "helm_release" "argo_cd" {
  name         = var.name
  namespace    = var.namespace
  replace      = true
  force_update = true
  repository   = "https://argoproj.github.io/argo-helm"
  chart        = "argo-cd"
  version      = var.chart_version

  values = [
    file("${path.module}/values.yaml")
  ]
  create_namespace = true
}

locals {
  rendered_values = templatefile("${path.module}/charts/values.tpl", {
    rds_endpoint = var.rds_endpoint
    rds_username = var.rds_username
    rds_db_name  = var.rds_db_name
    rds_password = var.rds_password
  })
}

resource "helm_release" "argo_apps" {
  name             = "${var.name}-apps"
  chart            = "${path.module}/charts"
  namespace        = var.namespace
  create_namespace = false

  values     = [local.rendered_values]
  depends_on = [helm_release.argo_cd]
}


terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
  }
}
resource "kubernetes_storage_class_v1" "ebs_sc" {
  metadata {
    name = "ebs-sc"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }
  storage_provisioner = "ebs.csi.aws.com"
  reclaim_policy      = "Delete"
  volume_binding_mode = "WaitForFirstConsumer"
  parameters = {
    type = "gp3"
  }
}

resource "kubernetes_service_account" "jenkins_sa" {
  metadata {
    name      = "jenkins-sa"
    namespace = "jenkins"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.jenkins_kaniko_role.arn
    }
  }
  depends_on = [
    helm_release.jenkins
  ]
}

locals {
  file_values = yamldecode(file("${path.module}/values.yaml"))
  dynamic_scripts = {
    credentials = <<-EOT
      credentials:
        system:
          domainCredentials:
            - credentials:
                - usernamePassword:
                    scope: GLOBAL
                    id: github-token
                    username: ${var.github_username}
                    password: ${var.github_token}
                    description: GitHub PAT
    EOT
    "seed-job"  = <<-EOT
      jobs:
        - script: >
            job('seed-job') {
              description('Job to generate pipeline for Django project')
              scm {
                git {
                  remote {
                    url("${var.github_repo_url}")
                    credentials('github-token')
                  }
                  branches("*/${var.github_branch}")
                }
              }
              steps {
                dsl {
                  text('''
                    pipelineJob("django-docker") {
                      definition {
                        cpsScm {
                          scriptPath('django/Jenkinsfile')
                          scm {
                            git {
                              remote {
                                url("${var.github_repo_url}")
                                credentials("github-token")
                              }
                              branches("*/${var.github_branch}")
                            }
                          }
                        }
                      }
                    }
                  ''')
                }
              }
            }
    EOT
  }
  jcasc_block = merge(
    {
      configScripts = local.dynamic_scripts
    }
  )
  controller_with_jcasc = merge(
    try(local.file_values.controller, {}),
    {
      JCasC = local.jcasc_block
    }
  )
  all_values = merge(
    local.file_values,
    {
      controller = local.controller_with_jcasc
    }
  )
}


resource "aws_iam_role" "jenkins_kaniko_role" {
  name = "${var.cluster_name}-jenkins-kaniko-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = var.oidc_provider_arn
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "${replace(var.oidc_provider_url, "https://", "")}:sub" = "system:serviceaccount:jenkins:jenkins-sa"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "jenkins_ecr_policy" {
  name = "${var.cluster_name}-jenkins-kaniko-ecr-policy"
  role = aws_iam_role.jenkins_kaniko_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeRepositories"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "helm_release" "jenkins" {
  name             = "jenkins"
  namespace        = "jenkins"
  replace          = true
  force_update     = true
  repository       = "https://charts.jenkins.io"
  chart            = "jenkins"
  version          = "5.8.27"
  create_namespace = true
  values           = [yamlencode(local.all_values)]
}

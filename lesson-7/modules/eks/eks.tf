# IAM-роль для EKS-кластера
resource "aws_iam_role" "eks" {
  # Ім'я IAM-ролі для кластера EKS
  name = "${var.cluster_name}-eks-cluster"

  # Політика, яка дозволяє сервісу EKS «асумувати» цю IAM-роль
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",  # Дозволяє AssumeRole (використання ролі)
      "Principal": {
        "Service": "eks.amazonaws.com"  # Дозволено для сервісу EKS
      }
    }
  ]
}
POLICY
}

# Прив'язка IAM-ролі до політики AmazonEKSClusterPolicy
resource "aws_iam_role_policy_attachment" "eks" {
  # ARN політики, що надає дозволи для EKS-кластера
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"

  # IAM-роль, до якої прив'язується політика
  role = aws_iam_role.eks.name
}

# Створення EKS-кластера
resource "aws_eks_cluster" "eks" {
  # Назва кластера
  name = var.cluster_name

  # ARN IAM-ролі, яка потрібна для керування кластером
  role_arn = aws_iam_role.eks.arn

  # Налаштування мережі (VPC)
  vpc_config {
    endpoint_private_access = true           # Включає приватний доступ до API-сервера
    endpoint_public_access  = true           # Включає публічний доступ до API-сервера
    subnet_ids              = var.subnet_ids # Список підмереж, де буде працювати EKS
  }

  # Налаштування доступу до EKS-кластера
  access_config {
    authentication_mode                         = "API" # Автентифікація через API
    bootstrap_cluster_creator_admin_permissions = true  # Надає адміністративні права користувачу, який створив кластер
  }

  # Залежність від IAM-політики для ролі EKS
  depends_on = [aws_iam_role_policy_attachment.eks]
}


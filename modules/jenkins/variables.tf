variable "cluster_name" {
  description = "Назва Kubernetes кластера"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN OIDC провайдера для EKS"
  type        = string

}

variable "oidc_provider_url" {
  description = "URL OIDC провайдера для EKS"
  type        = string
}

variable "github_username" {
  description = "GitHub username for Jenkins"
  type        = string
}

variable "github_token" {
  description = "GitHub token for Jenkins"
  type        = string
  sensitive   = true
}

variable "github_repo_url" {
  description = "GitHub repository URL for Jenkins"
  type        = string
}

variable "github_branch" {
  description = "GitHub branch for Jenkins"
  type        = string
}

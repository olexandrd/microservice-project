# Deployment Guide

## Prerequisites

Install and configure:

- AWS CLI with credentials for the target AWS account.
- Terraform.
- kubectl.
- Helm.
- Docker, if you want to build images locally.

The default AWS region is `us-east-2`.

## Configure Variables

Create a local `terraform.tfvars` file in the repository root. Do not commit this file.

```hcl
github_repo_url = "https://github.com/olexandrd/microservice-project.git"
github_branch   = "main"
github_username = "your_github_username"
github_token    = "your_github_pat"

rds_password                = "replace-me"
rds_publicly_accessible     = false
rds_use_aurora              = true
rds_multi_az                = true
rds_backup_retention_period = "7"
```

Common optional database settings:

```hcl
rds_username = "postgres"
rds_database_name = "myapp"
rds_instance_class = "db.t4g.medium"

rds_aurora_engine = "aurora-postgresql"
rds_aurora_engine_version = "15.3"
rds_aurora_parameter_group_family = "aurora-postgresql15"

rds_instance_engine = "postgres"
rds_instance_engine_version = "17.2"
rds_instance_parameter_group_family = "postgres17"
```

## Bootstrap Remote State

The `modules/s3-backend` module creates an S3 bucket and DynamoDB table for Terraform state and locking.

```sh
cd modules/s3-backend
terraform init
terraform plan
terraform apply
```

The root `backend.tf` is currently commented out. After creating the backend resources, uncomment and adjust the backend block if you want the root module to use remote state:

```hcl
terraform {
  backend "s3" {
    bucket         = "terraform-state-bucket-0011113-olexandr"
    key            = "terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
```

Then initialize from the repository root:

```sh
cd ../..
terraform init
```

## Provision the Platform

From the repository root:

```sh
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
```

Terraform creates the VPC, ECR repository, EKS cluster and node group, RDS or Aurora database, Kubernetes add-ons, Jenkins, Argo CD, and monitoring stack.

## Configure kubectl

After Terraform completes, configure local Kubernetes access:

```sh
aws eks --region us-east-2 update-kubeconfig --name eks-cluster-demo
kubectl get nodes
```

Check the main namespaces:

```sh
kubectl get all -n jenkins
kubectl get all -n argocd
kubectl get all -n monitoring
kubectl get all -n default
```

## Access Platform Services

Use port-forwarding for local access:

```sh
kubectl port-forward svc/jenkins 8080:80 -n jenkins
kubectl port-forward svc/argo-cd-argocd-server 8081:443 -n argocd
kubectl port-forward svc/kube-prometheus-stack-grafana 3000:80 -n monitoring
```

Then open:

- Jenkins: `http://localhost:8080`
- Argo CD: `https://localhost:8081`
- Grafana: `http://localhost:3000`

Get the initial Argo CD admin password:

```sh
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

## Build and Deploy the Django App

The intended CI/CD path is:

1. Open Jenkins.
2. Approve the seed job script under Jenkins script approval if required.
3. Create or run the generated pipeline job.
4. Jenkins builds the Docker image from `django/Dockerfile` with Kaniko.
5. Jenkins pushes the image to ECR.
6. Jenkins updates `charts/django-app/values.yaml` on the `cd` branch.
7. Argo CD detects the chart update and syncs the app.

Watch Argo CD:

```sh
kubectl get applications -n argocd
```

Watch the application:

```sh
kubectl get deploy,svc,ingress,hpa -n default
kubectl logs deploy/<release-name>-django -n default
```

## Deploy the Chart Manually

For local chart validation or manual deployment:

```sh
helm dependency update charts/django-app
helm template django charts/django-app
helm upgrade --install django charts/django-app \
  --namespace default \
  --set image.repository=<ecr-repo-url> \
  --set image.tag=<image-tag> \
  --set ingress.host=<your-domain>
```

Use `postgresql.enabled=true` if you want the chart dependency to create an in-cluster PostgreSQL instance for non-production testing.

## RDS Deployment Options

Create or update only the database module:

```sh
terraform apply -target=module.rds
```

Aurora with private access:

```sh
terraform apply -target=module.rds \
  -var="rds_use_aurora=true" \
  -var="rds_publicly_accessible=false"
```

Standard RDS with private access:

```sh
terraform apply -target=module.rds \
  -var="rds_use_aurora=false" \
  -var="rds_publicly_accessible=false"
```

Public database access is available through `rds_publicly_accessible=true`, but keep that setting for temporary testing only.

## Troubleshooting

Check Terraform outputs:

```sh
terraform output
```

Confirm EKS connectivity:

```sh
aws eks describe-cluster --region us-east-2 --name eks-cluster-demo
kubectl cluster-info
```

Check ingress controller:

```sh
kubectl get svc,pods -n kube-system | grep ingress
```

Check Argo CD application state:

```sh
kubectl describe application example-app -n argocd
```

Check image availability:

```sh
aws ecr describe-images --repository-name app --region us-east-2
```

## Teardown

Destroy the root stack first:

```sh
terraform destroy
```

Then remove the backend resources if they are no longer needed:

```sh
cd modules/s3-backend
terraform destroy
```

If Kubernetes load balancers or persistent volumes remain, delete them manually in AWS before retrying the destroy.

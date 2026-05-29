# Terraform Modules

## Root Module

The root module composes the full platform:

- `module.vpc`
- `module.ecr`
- `module.eks`
- `module.k8s_bootstrap`
- `module.monitoring`
- `module.jenkins`
- `module.argo_cd`
- `module.rds`

The root provider configuration uses AWS, Kubernetes, and Helm. The Kubernetes and Helm providers authenticate to the EKS cluster created by `module.eks`.

Root outputs include:

- `ecr_url`
- `eks_cluster_endpoint`
- `eks_cluster_name`
- `eks_node_role_arn`
- `jenkins_release`
- `jenkins_namespace`
- `rds_endpoint`

## vpc

Path: `modules/vpc`

Creates the networking foundation:

- VPC.
- Public subnets.
- Private subnets.
- Internet gateway.
- Public and private route tables.
- NAT EC2 instance for private subnet egress.
- Security group, IAM role, and instance profile for the NAT instance.

Important inputs:

| Input | Purpose |
| --- | --- |
| `vpc_cidr_block` | CIDR range for the VPC. |
| `public_subnets` | CIDR ranges for public subnets. |
| `private_subnets` | CIDR ranges for private subnets. |
| `availability_zones` | Availability zones for subnet placement. |
| `vpc_name` | Name prefix for VPC resources. |
| `name` | Project name used by related resources. |

Outputs:

- `vpc_id`
- `public_subnets`
- `private_subnets`
- `internet_gateway_id`
- `vpc_cidr_block`
- `nat_instance_id`

## ecr

Path: `modules/ecr`

Creates an ECR repository for the application image.

Important inputs:

| Input | Purpose |
| --- | --- |
| `ecr_name` | Repository name. Root uses `app`. |
| `scan_on_push` | Enables image scanning when images are pushed. |

Output:

- `ecr_url`

## eks

Path: `modules/eks`

Creates the EKS control plane, IAM roles, OIDC provider, access entries, and a managed node group.

Important inputs:

| Input | Purpose |
| --- | --- |
| `cluster_name` | EKS cluster name. |
| `subnet_ids` | Subnets for the EKS control plane. |
| `node_subnet_ids` | Subnets for worker nodes. |
| `instance_type` | Worker node instance type. |
| `desired_size` | Desired node count. |
| `min_size` | Minimum node count. |
| `max_size` | Maximum node count. |

Implementation notes:

- Node group capacity type is `SPOT`.
- Desired size is ignored after creation to avoid conflicts with cluster autoscaling behavior.
- EKS API endpoint has both private and public access enabled.
- The root AWS account principal is associated with cluster-admin access.

Outputs:

- `eks_cluster_endpoint`
- `eks_cluster_name`
- `eks_node_role_arn`
- `oidc_provider_arn`
- `oidc_provider_url`

## k8s_bootstrap

Path: `modules/k8s_bootstrap`

Installs cluster add-ons through Helm:

- `ingress-nginx` version `4.13.0`
- `metrics-server` version `3.12.2`

This module depends on EKS being available.

## monitoring

Path: `modules/monitoring`

Installs `kube-prometheus-stack` version `75.10.0` into the `monitoring` namespace.

The values file is `modules/monitoring/prometheus_values.yaml`.

Installed components include:

- Prometheus.
- Grafana.
- Alertmanager.
- kube-state-metrics.
- Prometheus node exporter.
- Prometheus operator.

## jenkins

Path: `modules/jenkins`

Installs Jenkins and configures build permissions.

Resources:

- Jenkins Helm release version `5.8.27`.
- Kubernetes storage class `ebs-sc` using the AWS EBS CSI driver.
- Kubernetes service account `jenkins-sa`.
- IAM role for the service account through EKS OIDC.
- IAM policy that allows Kaniko builds to push images to ECR.

Important inputs:

| Input | Purpose |
| --- | --- |
| `cluster_name` | Used in IAM resource names. |
| `oidc_provider_arn` | EKS OIDC provider ARN for IRSA. |
| `oidc_provider_url` | EKS OIDC provider URL for trust policy conditions. |
| `github_username` | GitHub credential username for Jenkins. |
| `github_token` | GitHub token for Jenkins. |
| `github_repo_url` | Repository used by Jenkins jobs. |
| `github_branch` | Source branch used by Jenkins jobs. |

Outputs:

- `jenkins_release_name`
- `jenkins_namespace`

## argo_cd

Path: `modules/argo_cd`

Installs Argo CD and an app-of-apps chart.

Resources:

- Argo CD Helm release from `argoproj/argo-helm`.
- Local apps chart from `modules/argo_cd/charts`.

The apps chart creates an Argo CD application named `example-app`. It watches:

- Repository: `https://github.com/olexandrd/microservice-project.git`
- Path: `charts/django-app`
- Target revision: `cd`
- Destination namespace: `default`

The module receives the RDS endpoint and renders database values into the application Helm values.

Important inputs:

| Input | Purpose |
| --- | --- |
| `name` | Argo CD Helm release name. |
| `namespace` | Namespace for Argo CD. |
| `chart_version` | Argo CD chart version. |
| `rds_username` | Database username passed to the app. |
| `rds_db_name` | Database name passed to the app. |
| `rds_password` | Database password passed to the app. |
| `rds_endpoint` | Database endpoint passed to the app. |

Outputs:

- `argo_cd_server_service`
- `admin_password` helper command

## rds

Path: `modules/rds`

Creates either a standard PostgreSQL RDS instance or an Aurora PostgreSQL cluster.

Mode selection:

- `use_aurora = true` creates Aurora resources.
- `use_aurora = false` creates standard RDS resources.

Shared resources include:

- DB subnet group.
- PostgreSQL security group.
- Parameter groups.

Important inputs:

| Input | Purpose |
| --- | --- |
| `name` | DB instance or cluster name prefix. |
| `use_aurora` | Selects Aurora or standard RDS. |
| `db_name` | Initial database name. |
| `username` | Master username. |
| `password` | Master password. |
| `vpc_id` | VPC where the database runs. |
| `vpc_cidr_block` | CIDR allowed to access PostgreSQL. |
| `subnet_private_ids` | Private subnet IDs. |
| `subnet_public_ids` | Public subnet IDs. |
| `publicly_accessible` | Chooses public/private placement and exposure. |
| `multi_az` | Standard RDS Multi-AZ setting. |
| `backup_retention_period` | Retention period in days. |
| `parameters` | DB parameter map. |
| `instance_class` | DB instance class. |

Implementation notes:

- Standard RDS uses `skip_final_snapshot = true`.
- Aurora uses `skip_final_snapshot = false` and writes a final snapshot named from the DB name.
- Root Terraform currently passes `aurora_instance_count = 2`, but the Aurora implementation uses `aurora_replica_count` for reader instances.

## s3-backend

Path: `modules/s3-backend`

Creates remote state resources:

- S3 bucket for Terraform state.
- DynamoDB table for state locking.

Important inputs:

| Input | Purpose |
| --- | --- |
| `bucket_name` | S3 bucket name. |
| `table_name` | DynamoDB lock table name. |

Outputs:

- `s3_bucket_name`
- `dynamodb_table_name`

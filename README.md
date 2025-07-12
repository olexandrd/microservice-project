# Application Deployment with CD Pipeline

This directory contains the source code and resources for homework 8 and 9, focusing on setup CD pipeline.

*Disclaimer: NAT instance is used for outbound internet access instead of an AWS NAT Gateway for the
cost savings.
Spot instances on EKS nodes are used for the same reason.*

*Disclaimer: Chart is configured to use `django.stage.fixer.tools` domain for application and ingress.
But setting up domain is out of scope for this task.
`django.stage.fixer.tools` was configured manually to point to created Load Balancer.
You can use your own domain instead of `django.stage.fixer.tools` and point it to the Load Balancer
that is created during your Helm chart deployment
(helm install ... --set ingress.host=your_domain or redefine in ArgoCD).*

## Prerequisites

- AWS CLI installed and configured
- kubectl installed
- Helm installed
- Docker installed
- Terraform installed

## Steps to set up the environment

For this task, we will use an EKS cluster in the `us-east-2` region.
There is 2 step to initialize the project, first you need to initialize the remote
backend and then the main project.

```sh
cd modules/s3-backend
terraform init
terraform plan
terraform apply

```

After backend is initialized, you can go back to the repo root directory and deploy EKS cluster.

```sh
cd ../../
terraform init
terraform plan
terraform apply

```

## Access to CD pipeline

Needed endpoints, Jenkins and ArgoCD, can be found on the AWS console, under EC2 Load Balancers.

## Build and push Docker image to ECR

To build and push the Docker image to ECR, follow these steps:

- Open Jenkins in your browser (the URL can be found in the AWS console under EC2 Load Balancers).
- On Jenkins settings page select Script Approval and approve seed job script.
- Create a new pipeline job using the seed job.
- Run the pipeline job to build the Docker image and push it to ECR.

Example:
![alt text](docs/img/jenkins-01.png)

## Configure cluster

To configure your local `kubectl` to connect to the EKS cluster, run the following command:

```sh
aws eks --region us-east-2 update-kubeconfig --name $EKS_CLUSTER_NAME
# or
aws eks --region us-east-2 update-kubeconfig --name eks-cluster-demo
```

## Argo CD integration

Terraform configuration includes Argo CD setup.
ArgoCD applications and repositories are defined in the `modules/argo_cd/charts` directory and
created during the Terraform apply.

For controlling ArgoCD applications, you can use the ArgoCD UI.
ArgoCD URL can be found in the AWS console under EC2 Load Balancers.
To access the ArgoCD UI, you need to get the initial admin password. Run the following command:

```sh
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

## Deploy Django application

CD pipeline uses Jenkins only.
It can be verified in Argocd UI.

- Before Jenkins job execution, ArgoCD application is in `OutOfSync` state.
![alt text](docs/img/argocd-01.png)
- After Jenkins job execution, ArgoCD application is in `Synced` state.
![alt text](docs/img/argocd-02.png)
- ArgoCD UI shows the deployed application and its resources.
![alt text](docs/img/argocd-03.png)

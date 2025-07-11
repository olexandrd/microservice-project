# Lesson 7: Helm Chart Deployment

This directory contains the source code and resources for homework 7, focusing on deploying a Helm chart.

*Disclaimer: NAT instance is used for outbound internet access instead of an AWS NAT Gateway for the
cost savings.
Spot instances on EKS nodes are used for the same reason.*

## Prerequisites

- AWS CLI installed and configured
- kubectl installed
- Helm installed
- Docker installed
- Terraform installed

## Steps to set up the environment

For this task, we will use an EKS cluster in the `us-east-2` region.
There is 2 step to initialize the project, first you need to initialize the remote backend and then the main project.

```sh
cd lesson-7/modules/s3-backend
terraform init
terraform plan
terraform apply

```

After backend is initialized, you can go back to the `lesson-7` directory and deploy EKS cluster.

```sh
cd ../../
terraform init
terraform plan
terraform apply

```

We need output from the Terraform deployment to configure the EKS cluster and deploy our Helm chart.
To simplify the process, lets export the output values to environment variables.

```sh
export ECR_REPO=$(terraform output -raw ecr_url)
export EKS_CLUSTER_NAME=$(terraform output -raw eks_cluster_name)
```

## Build and push Docker image to ECR

Use the following commands to build and push the Docker image to ECR.

```sh
aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin $(echo $ECR_REPO | egrep -o "^.*com")

docker buildx create --use

docker buildx build --platform linux/amd64,linux/arm64 \
  --tag $ECR_REPO \
  --push .

```

## Configure cluster

To configure your local `kubectl` to connect to the EKS cluster, run the following command:

```sh
aws eks --region us-east-2 update-kubeconfig --name $EKS_CLUSTER_NAME
```

We need to install the NGINX Ingress Controller.

```sh
# Install NGINX Ingress Controller
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.publishService.enabled=true

```

For HPA (Horizontal Pod Autoscaler) to work correctly, we need to enable the metrics server in the cluster.

```sh
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

## Deploy Django application using Helm

As we use PostgreSQL as a database, we need to download helm dependencies first by `dependency build`.
After that, we can deploy the Django application using Helm.

```sh
helm dependency build ./charts/django-app

helm install django ./charts/django-app \
  --set postgresql.enabled=true \
  --set image.repository=$ECR_REPO
```

*Disclaimer: Chart is configured to use `django.stage.fixer.tools` domain for application and ingress.
But setting up domain is out of scope for this task.
`django.stage.fixer.tools` was configured manually to point to created Load Balancer.
You can use your own domain instead of `django.stage.fixer.tools` and point it to the Load Balancer
that is created during your Helm chart deployment
(helm install ... --set ingress.host=your_domain).*

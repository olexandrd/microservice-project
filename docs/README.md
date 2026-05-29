# Documentation

This directory contains operational and reference documentation for the microservice platform.

## Start here

- [Architecture](architecture.md) explains the AWS, Kubernetes, CI/CD, database, and monitoring design.
- [Deployment Guide](deployment.md) walks through provisioning, cluster access, CI/CD, app deployment, and teardown.
- [Terraform Modules](terraform-modules.md) summarizes every module, its responsibilities, inputs, outputs, and important implementation notes.
- [Application](application.md) documents the Django service, Docker image, Helm chart, runtime configuration, and local development flow.

## Repository layout

```text
.
|-- main.tf                    # Root Terraform composition
|-- variables.tf               # Root Terraform inputs
|-- outputs.tf                 # Root Terraform outputs
|-- modules/                   # Reusable Terraform modules
|-- charts/django-app/         # Helm chart for the Django app
|-- django/                    # Django project, Dockerfile, Jenkins pipeline
|-- docs/img/                  # Screenshots used by the root README
`-- README.md                  # Original walkthrough with screenshots
```

## Platform summary

The repository provisions a demo Django application platform on AWS:

- VPC with public and private subnets across three availability zones.
- EKS cluster with a SPOT managed node group in private subnets.
- ECR repository for the Django image.
- Optional Aurora PostgreSQL or standard RDS PostgreSQL database.
- Kubernetes bootstrap add-ons for ingress-nginx and metrics-server.
- Jenkins for image builds and chart tag updates.
- Argo CD for GitOps deployment of the Helm chart.
- kube-prometheus-stack for Prometheus, Grafana, Alertmanager, and exporters.

The root [README.md](../README.md) remains useful as a screenshot-rich walkthrough. These docs are meant to be a more structured reference for operating and changing the repo.

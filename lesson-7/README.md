# Lesson 7: Helm Chart Deployment

This directory contains the source code and resources for Lesson 7, focusing on deploying a Helm chart.

*Disclaimer: Instead of using EKS, this example runs a self-managed Kubernetes cluster for cost reduction purposes. Also, NAT instance is used for outbound internet access instead of an AWS NAT Gateway for the
same reason.*

*Note. Output of `terraform output -raw kubeconfig_instructions` command will rewrite any existing kubeconfig files.
**Use with caution!***

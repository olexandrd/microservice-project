# Lesson 7: Helm Chart Deployment

This directory contains the source code and resources for Lesson 7, focusing on deploying a Helm chart.

*Disclaimer: NAT instance is used for outbound internet access instead of an AWS NAT Gateway for the
same reason.*

```sh
aws eks --region us-east-2 update-kubeconfig --name eks-cluster-demo
```

```sh
kubectl apply -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ebs-sc
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: ebs.csi.aws.com
parameters:
  type: gp3
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
EOF

aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin 290480495560.dkr.ecr.us-east-2.amazonaws.com

docker buildx create --use

docker buildx build --platform linux/amd64,linux/arm64 \
  --tag 290480495560.dkr.ecr.us-east-2.amazonaws.com/lesson-7-ecr \
  --push .

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
kubectl create ns ingress-nginx

helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --set controller.publishService.enabled=true

helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --set installCRDs=true


helm dependency build ./charts/django-app

helm install django ./charts/django-app \
  --set postgresql.enabled=true \
  --set image.repository=290480495560.dkr.ecr.us-east-2.amazonaws.com/lesson-7-ecr
```

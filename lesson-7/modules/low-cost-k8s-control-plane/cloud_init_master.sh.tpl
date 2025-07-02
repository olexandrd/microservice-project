#!/bin/bash
set -e

# 1. Kernel modules
cat <<EOF | sudo tee /etc/modules-load.d/kubernetes.conf
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter

# 2. Sysctl
cat <<EOF | sudo tee /etc/sysctl.d/kubernetes.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
EOF
sudo sysctl --system

# 3. Disable swap (на AL2023 swap вже відключений, але для гарантії:)
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab || true

# 4. kubeadm init & SSM logic
KUBEADM_TOKEN=$(aws ssm get-parameter --name "${kubeadm_token_ssm_name}" --region ${region} --with-decryption --query "Parameter.Value" --output text)
POD_CIDR="${pod_network_cidr}"
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

sudo kubeadm init \
  --token $KUBEADM_TOKEN \
  --pod-network-cidr=$POD_CIDR \
  --apiserver-cert-extra-sans=$PUBLIC_IP \
  --ignore-preflight-errors=all

HASH=$(openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | \
    openssl rsa -pubin -outform der 2>/dev/null | \
    openssl dgst -sha256 -hex | \
    sed 's/^.* //')
HASH="sha256:$HASH"
aws ssm put-parameter --name "${ca_hash_ssm_name}" --value "$HASH" \
  --type "String" --overwrite --region ${region}

# 5. kubeconfig (root/ssm)
mkdir -p /root/.kube
cp /etc/kubernetes/admin.conf /root/.kube/config

aws ssm put-parameter \
  --name "/k8s/admin.conf" \
  --type "SecureString" \
  --value "$(sudo cat /etc/kubernetes/admin.conf)" \
  --overwrite \
  --tier Advanced \
  --region ${region}

# 6. Network (AWS VPC CNI — AL2023 EKS-optimized сам ставить aws-node, але якщо треба вручну):
kubectl --kubeconfig=/etc/kubernetes/admin.conf apply \
  -f https://raw.githubusercontent.com/aws/amazon-vpc-cni-k8s/v1.19.6/config/v1.19/aws-k8s-cni.yaml

# 7. Дати sudo доступ ec2-user (або іншому юзеру)
cp /etc/kubernetes/admin.conf /home/ec2-user/.kube/config
chown ec2-user:ec2-user /home/ec2-user/.kube/config

echo "K8s master node on AL2023 cloud-init done"

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

# 3. Disable swap (AL2023 swap зазвичай вже немає)
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab || true

# Install kubeadm and kubectl

sudo mkdir -p /etc/eks/kubelet/
sudo touch  /etc/eks/kubelet/environment
sudo touch /etc/sysconfig/kubelet


cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.32/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.32/rpm/repodata/repomd.xml.key
EOF
sudo yum install -y kubeadm kubectl iproute-tc

sudo systemctl enable kubelet.service
sudo systemctl start kubelet.service

# 4. Wait for CA hash in SSM
while true; do
  CA_HASH=$(aws ssm get-parameter \
    --name "${ca_hash_ssm_name}" \
    --region ${region} \
    --with-decryption \
    --query "Parameter.Value" \
    --output text)
  if [[ $CA_HASH == sha256* ]]; then
    break
  fi
  echo "Waiting for CA cert hash in SSM..."
  sleep 10
done

# 5. Get kubeadm token and join
KUBEADM_TOKEN=$(aws ssm get-parameter \
  --name "${kubeadm_token_ssm_name}" \
  --region ${region} \
  --with-decryption \
  --query "Parameter.Value" \
  --output text)

sudo kubeadm join ${master_ip}:6443 \
  --token $KUBEADM_TOKEN \
  --discovery-token-ca-cert-hash $CA_HASH \
  --ignore-preflight-errors=all

echo "K8s worker node on AL2023 cloud-init done"

#!/bin/bash
set -e

# 1. Kernel modules
sudo tee /etc/modules-load.d/kubernetes.conf <<EOF
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter

# 2. Sysctl
sudo tee /etc/sysctl.d/kubernetes.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
EOF
sudo sysctl --system

# 3. Disable swap
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# 4. Install prerequisites
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common jq awscli

# 5. Docker repo & install
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  `lsb_release -cs` stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update && sudo apt-get install -y docker-ce docker-ce-cli containerd.io


containerd config default \
  | sed 's/SystemdCgroup = false/SystemdCgroup = true/' \
  | sudo tee /etc/containerd/config.toml
sudo mkdir -p /etc/docker
cat <<EOF | sudo tee /etc/docker/config.json
{
  "credsStore": "ecr-login"
}
EOF

sudo sed -i '/[plugins\."io.containerd.grpc.v1.cri"\.registry\]/,/^\[/ s|config_path *= *""|config_path ="/etc/docker"|' /etc/containerd/config.toml

sudo systemctl restart containerd
sudo systemctl enable --now containerd

# 6. Kubernetes repo
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | \
  sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | \
  sudo tee /etc/apt/sources.list.d/kubernetes.list

# 7. Install Kubernetes tools
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl amazon-ecr-credential-helper
sudo systemctl enable --now containerd

# 8. kubeadm init & SSM logic
KUBEADM_TOKEN=$(aws ssm get-parameter --name "${kubeadm_token_ssm_name}" \
  --region ${region} --with-decryption --query "Parameter.Value" --output text)
POD_CIDR="${pod_network_cidr}"

PUBLIC_IP=`curl -s http://169.254.169.254/latest/meta-data/public-ipv4`

sudo kubeadm init \
  --token $KUBEADM_TOKEN \
  --pod-network-cidr=$POD_CIDR \
  --apiserver-cert-extra-sans=$PUBLIC_IP \
  --control-plane-endpoint=$PUBLIC_IP:6443 \
  --ignore-preflight-errors=all

HASH=$(openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt \
    | openssl rsa -pubin -outform der 2>/dev/null \
    | openssl dgst -sha256 -hex \
    | sed 's/^.* //')
HASH="sha256:$HASH"
aws ssm put-parameter --name "${ca_hash_ssm_name}" --value "$HASH" \
  --type "String" --overwrite --region ${region}

# 9. Configure local kubeconfig
mkdir -p /root/.kube
mkdir -p /home/ubuntu/.kube
cp /etc/kubernetes/admin.conf /root/.kube/config
cp /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
chown ubuntu:ubuntu /home/ubuntu/.kube/config

# 10. Store kubeconfig in SSM
aws ssm put-parameter \
  --name "/k8s/admin.conf" \
  --type "SecureString" \
  --value "$(sudo cat /etc/kubernetes/admin.conf)" \
  --overwrite \
  --tier Advanced \
  --region ${region}

# 11. Deploy CNI
kubectl --kubeconfig=/etc/kubernetes/admin.conf apply \
  -f https://raw.githubusercontent.com/aws/amazon-vpc-cni-k8s/refs/heads/master/config/master/aws-k8s-cni.yaml


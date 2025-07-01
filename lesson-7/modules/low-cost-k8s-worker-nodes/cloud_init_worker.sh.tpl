#!/bin/bash
set -e

# 1. Завантаження kernel-модулів
sudo tee /etc/modules-load.d/kubernetes.conf <<EOF
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter

# 2. Налаштування sysctl
sudo tee /etc/sysctl.d/kubernetes.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
EOF
sudo sysctl --system

# 3. Вимкнення swap
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# 4. Встановлення потрібних пакетів
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl \
     software-properties-common jq awscli

# 5. Додати Docker-репозиторій (щоб мати останню версію containerd.io)
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
sudo systemctl enable --now containerd

# 6. Kubernetes repo
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | \
  sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | \
  sudo tee /etc/apt/sources.list.d/kubernetes.list


# 7. Оновити індекси та встановити containerd і Kubernetes-бінарі
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl amazon-ecr-credential-helper


# 8. Налаштувати containerd на systemd cgroup
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

# 9. Чекати появи CA hash у SSM
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

# 10. Отримати kubeadm token та приєднатися
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

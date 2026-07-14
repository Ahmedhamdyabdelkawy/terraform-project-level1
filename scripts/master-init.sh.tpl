#!/bin/bash
set -euxo pipefail
exec > >(tee /var/log/user-data.log) 2>&1

############################################
# Base OS prep (common to master & worker)
############################################

swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

cat <<EOF > /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF
modprobe overlay
modprobe br_netfilter

cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sysctl --system

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y ca-certificates curl gnupg apt-transport-https

# containerd
apt-get install -y containerd
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl restart containerd
systemctl enable containerd

# kubeadm / kubelet / kubectl
mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v${kubernetes_version}/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${kubernetes_version}/deb/ /" > /etc/apt/sources.list.d/kubernetes.list

apt-get update -y
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl
systemctl enable kubelet

############################################
# Master-only: kubeadm init + Calico + join token
############################################

TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
PRIVATE_IP=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/local-ipv4)

kubeadm init \
  --pod-network-cidr=${pod_network_cidr} \
  --apiserver-advertise-address="$PRIVATE_IP" \
  --node-name=master

mkdir -p /home/ubuntu/.kube
cp -i /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
chown -R ubuntu:ubuntu /home/ubuntu/.kube
mkdir -p /root/.kube
cp -i /etc/kubernetes/admin.conf /root/.kube/config

export KUBECONFIG=/etc/kubernetes/admin.conf
kubectl apply -f "https://raw.githubusercontent.com/projectcalico/calico/${calico_version}/manifests/calico.yaml"

# Save a ready-to-run join command for the worker (long-lived token)
kubeadm token create --print-join-command --ttl 0 > /home/ubuntu/join-command.sh
chmod +x /home/ubuntu/join-command.sh
chown ubuntu:ubuntu /home/ubuntu/join-command.sh

touch /home/ubuntu/.master-init-complete
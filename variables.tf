variable "aws_region" {
  description = "AWS region to deploy the Kubernetes cluster"
  type        = string
  default     = "eu-west-3" # Paris
}

variable "project_name" {
  description = "Prefix used for naming and tagging all AWS resources"
  type        = string
  default     = "k8s-cluster"
}

variable "instance_type" {
  description = "EC2 instance type used for both the Kubernetes master and worker nodes (2 vCPU, 8 GiB RAM)"
  type        = string
  default     = "m7i-flex.large"
}

variable "root_volume_size" {
  description = "Root EBS volume size in GiB for each EC2 instance"
  type        = number
  default     = 20
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to access SSH (22) and the Kubernetes API server (6443). Restrict this to your public IP in production."
  type        = string
  default     = "0.0.0.0/0"
}

variable "pod_network_cidr" {
  description = "Pod network CIDR used by kubeadm and Calico"
  type        = string
  default     = "192.168.0.0/16"
}

variable "kubernetes_version" {
  description = "Kubernetes minor version to install"
  type        = string
  default     = "1.30"
}

variable "calico_version" {
  description = "Calico CNI version"
  type        = string
  default     = "v3.28.0"
}
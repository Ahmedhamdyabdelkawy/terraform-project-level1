# terraform-project-level1
```markdown
# terraform-project-level1

A **Terraform** project that fully automates the deployment of a simple **Kubernetes** cluster (Master + Worker) on **AWS**, using `kubeadm`, with built-in centralized logging via S3.

## Overview

This project provisions a Kubernetes cluster from scratch on AWS with zero manual intervention. It handles:

- Creating the EC2 instances (Master and Worker).
- Setting up networking and security.
- Installing and configuring Kubernetes automatically at boot time (via user data scripts).
- Automatically joining the Worker node to the Master once both finish initializing (no manual commands needed).
- Collecting logs in a dedicated S3 bucket for monitoring and auditing.

## Core Components (Resources)

### 1. SSH Key Pair
- A new key pair is generated automatically (`tls_private_key`) and uploaded to AWS (`aws_key_pair`).
- The private key is saved locally as a `.pem` file so you can SSH into the instances.

### 2. Networking
- The project uses the account's **Default VPC** and default **Subnets**, without creating a custom VPC (kept simple on purpose).
- The latest official **Ubuntu 22.04** AMI from Canonical is selected automatically.

### 3. Security Group
A single security group shared by both the Master and Worker, allowing:
- SSH (port 22).
- Kubernetes API server (port 6443).
- NodePort range (30000–32767) so you can reach exposed services externally.
- All internal traffic between cluster nodes themselves (etcd, kubelet, Calico, etc.).

### 4. Cluster Nodes (EC2 Instances)
- **Master Node**: runs `kubeadm init`, installs **Calico** as the CNI, and prepares the join command for Workers.
- **Worker Node**: gets the same base setup (containerd, kubelet, kubeadm...) and waits to receive the join command.

### 5. Automatic Cluster Join
- A `null_resource` with a `local-exec` provisioner runs the `scripts/join-cluster.sh` script locally (on the machine where you run `terraform apply`).
- This script waits until both the Master and Worker finish their initial cloud-init setup, then fetches the join command from the Master and runs it on the Worker automatically. Finally, it verifies the cluster is healthy via `kubectl get nodes`.

### 6. Logging (via S3)
- A dedicated **S3 bucket** for logs, fully blocked from public access.
- **VPC Flow Logs** enabled to capture all inbound/outbound traffic in the VPC.
- An **IAM Role/Instance Profile** allowing the EC2 instances (Master/Worker) to upload their own logs to the same bucket.
- An automatic **Lifecycle policy** that expires old logs after 90 days to save on cost.

## File Structure

```
terraform-project-level1/
├── main.tf                     # Core resources (networking, instances, logging, SG...)
├── variables.tf                 # Configurable variables (instance type, region...)
├── provider.tf                  # AWS provider setup and Terraform requirements
├── outputs.tf                   # Outputs (IPs, SSH commands, key path...)
├── scripts/
│   ├── master-init.sh.tpl       # Master initialization script (kubeadm init + Calico)
│   ├── worker-init.sh.tpl       # Worker initialization script
│   └── join-cluster.sh          # Automatic join script that runs after boot
└── README.md
```

## Variables

| Variable | Description | Default |
|---|---|---|
| `aws_region` | AWS region to deploy the cluster in | `eu-west-3` (Paris) |
| `project_name` | Prefix used for naming and tagging all resources | `k8s-cluster` |
| `instance_type` | EC2 instance type for both Master and Worker nodes | `m7i-flex.large` |
| `root_volume_size` | Root EBS volume size per instance (GiB) | `20` |
| `allowed_ssh_cidr` | CIDR block allowed to access SSH and the API server | `0.0.0.0/0` |
| `pod_network_cidr` | Pod network CIDR (used by kubeadm and Calico) | `192.168.0.0/16` |
| `kubernetes_version` | Kubernetes minor version to install | `1.30` |
| `calico_version` | Calico CNI version | `v3.28.0` |

> Note: the default `allowed_ssh_cidr` is open to the whole world (`0.0.0.0/0`). Restrict it to your own IP in any production-like environment.

## Usage

```bash
# Initialize Terraform and download providers
terraform init

# Review the execution plan
terraform plan

# Deploy the full cluster
terraform apply
```

Once `apply` completes, the outputs will give you:
- Public IPs for the Master and Worker nodes.
- Ready-to-use SSH commands for each node.
- A ready-to-use command to pull the kubeconfig locally for remote cluster access.
- The name of the S3 bucket containing the logs.

## Destroying the Infrastructure

```bash
terraform destroy
```

## Notes

- This project is designed for learning/demo purposes (Level 1) — it does not use a custom VPC, Multi-AZ, or High Availability for the Master.
- The `local-exec` provisioner in `main.tf` currently relies on a Windows Git Bash path (`D:/Git/usr/bin/bash.exe`). If you're running this on Linux/Mac, update or remove the `interpreter` line.
- The generated private key (`*.pem`) is saved locally in the project directory — keep it out of version control (it's already covered in `.gitignore`).
```

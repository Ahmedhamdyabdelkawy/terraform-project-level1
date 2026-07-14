# terraform-project-level1
Architecture.png
A **Terraform** project that provisions a **Kubernetes cluster (Master + Worker)** on **AWS** using **kubeadm**, with automated cluster initialization, centralized logging, and minimal manual intervention.

## Overview

This project automates the deployment of a Kubernetes cluster by:

* Provisioning EC2 instances for the **Master** and **Worker** nodes.
* Using the AWS **Default VPC** and **Default Subnets**.
* Installing and configuring Kubernetes components automatically using **cloud-init**.
* Installing **containerd** as the container runtime and **Calico** as the CNI plugin.
* Automatically joining the Worker node to the cluster after initialization.
* Collecting both **VPC Flow Logs** and **EC2 instance logs** into an S3 bucket.

## Infrastructure

* **Ubuntu 22.04** EC2 instances
* **AWS Default VPC / Subnets**
* Shared **Security Group**
* **IAM Role & Instance Profile**
* **Amazon S3** for centralized logging
* **VPC Flow Logs**
* Automatically generated **SSH Key Pair**

## Security Group Rules

| Port                     | Purpose                                                               |
| ------------------------ | --------------------------------------------------------------------- |
| **22**                   | SSH access                                                            |
| **6443**                 | Kubernetes API Server                                                 |
| **30000–32767**          | Kubernetes NodePort Services                                          |
| **All Internal Traffic** | Communication between Master and Worker (kubelet, etcd, Calico, etc.) |

## Cluster Automation

The cluster is fully bootstrapped without manual Kubernetes commands:

* Master initializes the cluster using `kubeadm init`.
* Calico networking is installed automatically.
* Worker waits until the Master is ready.
* A Terraform `null_resource` executes `join-cluster.sh` to retrieve the join command and automatically add the Worker node to the cluster.
* The deployment is verified using `kubectl get nodes`.

## Logging

Centralized logging is configured through:

* **VPC Flow Logs** → Amazon S3
* **EC2 Instance Logs** → Amazon S3 (via IAM Role)
* S3 bucket with **Public Access Block**
* **90-day Lifecycle Policy** for automatic log cleanup

## Deployment

```bash
terraform init
terraform plan
terraform apply
```

## Architecture

> The architecture diagram below illustrates the complete infrastructure provisioned by Terraform, including networking, security, Kubernetes nodes, IAM, and centralized logging.

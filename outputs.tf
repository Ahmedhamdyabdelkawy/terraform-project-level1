output "master_public_ip" {
  description = "Public IP of the master node"
  value       = aws_instance.master.public_ip
}

output "worker_public_ip" {
  description = "Public IP of the worker node"
  value       = aws_instance.worker.public_ip
}

output "private_key_path" {
  description = "Local path to the generated SSH private key"
  value       = local_file.private_key.filename
}

output "ssh_master" {
  description = "Command to SSH into the master node"
  value       = "ssh -i ${local_file.private_key.filename} ubuntu@${aws_instance.master.public_ip}"
}

output "ssh_worker" {
  description = "Command to SSH into the worker node"
  value       = "ssh -i ${local_file.private_key.filename} ubuntu@${aws_instance.worker.public_ip}"
}

output "get_kubeconfig" {
  description = "Command to copy the cluster kubeconfig to your local machine"
  value       = "scp -i ${local_file.private_key.filename} ubuntu@${aws_instance.master.public_ip}:/home/ubuntu/.kube/config ./kubeconfig && export KUBECONFIG=./kubeconfig"
}

output "logs_bucket_name" {
  description = "S3 bucket receiving VPC Flow Logs (vpc-flow-logs/) and instance/system logs (instance-logs/)"
  value       = aws_s3_bucket.logs.bucket
}

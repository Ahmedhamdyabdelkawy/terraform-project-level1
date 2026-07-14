#!/bin/bash
# Runs on the machine executing `terraform apply`.
# Waits for both nodes' user_data (cloud-init) to finish, then
# pulls the join command off the master and runs it on the worker.
set -euo pipefail

MASTER_IP="$1"
WORKER_IP="$2"
KEY_PATH="$3"

SSH="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=5 -i ${KEY_PATH} ubuntu@"

echo ">> Waiting for master ($MASTER_IP) cloud-init to finish..."
until $SSH"$MASTER_IP" "test -f /home/ubuntu/.master-init-complete" 2>/dev/null; do
  sleep 15
  echo "   ...still waiting on master"
done
echo ">> Master is ready."

echo ">> Waiting for worker ($WORKER_IP) cloud-init to finish..."
until $SSH"$WORKER_IP" "test -f /home/ubuntu/.worker-init-complete" 2>/dev/null; do
  sleep 15
  echo "   ...still waiting on worker"
done
echo ">> Worker is ready."

echo ">> Fetching join command from master..."
JOIN_CMD=$($SSH"$MASTER_IP" "cat /home/ubuntu/join-command.sh")

echo ">> Joining worker to the cluster..."
$SSH"$WORKER_IP" "sudo $JOIN_CMD"

echo ">> Verifying from master..."
$SSH"$MASTER_IP" "kubectl get nodes -o wide" || true

echo ">> Done. Worker has joined the cluster."

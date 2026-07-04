# Runbook

## Provision from Zero

### 1. Prerequisites
```bash
# Install tools
sudo apt-get install -y awscli ansible
# Install terraform
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt-get install terraform
```

### 2. Configure AWS
```bash
aws configure
# Enter Access Key ID, Secret Access Key, region: eu-north-1, format: json
```

### 3. Bootstrap Remote State
```bash
aws s3api create-bucket --bucket capstone-phoenix-tfstate-730667139972 --region eu-north-1 --create-bucket-configuration LocationConstraint=eu-north-1
aws s3api put-bucket-versioning --bucket capstone-phoenix-tfstate-730667139972 --versioning-configuration Status=Enabled
aws dynamodb create-table --table-name capstone-phoenix-tflock --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema AttributeName=LockID,KeyType=HASH --billing-mode PAY_PER_REQUEST --region eu-north-1
```

### 4. Create Infrastructure
```bash
cd infra/terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform init
terraform apply
```

### 5. Create Cluster
```bash
cd ~/capstone-phoenix
ansible-playbook -i infra/ansible/inventory.ini infra/ansible/site.yml
```

### 6. Fix Worker Private IP (required after fresh install)
SSH into each worker and run:
```bash
sudo -i
cat > /etc/systemd/system/k3s-agent.service.env << 'EOF2'
K3S_TOKEN='<token from control plane /var/lib/rancher/k3s/server/node-token>'
K3S_URL='https://<control-plane-private-ip>:6443'
EOF2
systemctl daemon-reload
rm -rf /var/lib/rancher/k3s/agent
systemctl start k3s-agent
```

### 7. Configure kubectl
```bash
ssh -i ~/.ssh/capstone-key.pem ubuntu@<control-plane-public-ip> "sudo chmod 644 /etc/rancher/k3s/k3s.yaml"
scp -i ~/.ssh/capstone-key.pem ubuntu@<control-plane-public-ip>:/etc/rancher/k3s/k3s.yaml ~/.kube/config
# Start SSH tunnel in separate terminal:
ssh -i ~/.ssh/capstone-key.pem -L 6443:localhost:6443 ubuntu@<control-plane-public-ip> -N
```

### 8. Deploy App via GitOps
```bash
kubectl apply -f gitops/taskapp-application.yaml
# Argo CD will automatically sync all manifests from git
```

## Scale

### Manual scale
```bash
kubectl scale deployment backend -n taskapp --replicas=3
```

### HPA is automatic
The backend HPA scales between 2-5 replicas based on CPU (50%) and memory (70%) thresholds.

## Roll Back

### Roll back a deployment
```bash
kubectl rollout undo deployment/backend -n taskapp
kubectl rollout undo deployment/frontend -n taskapp
```

### Roll back via GitOps
```bash
git revert HEAD
git push
# Argo CD will auto-sync the revert
```

## Recover from a Dead Worker

### Worker node goes down
Kubernetes automatically reschedules pods to healthy nodes after 5 minutes.

### Manually fix a worker that won't rejoin
```bash
ssh -i ~/.ssh/capstone-key.pem ubuntu@<worker-public-ip>
sudo -i
systemctl stop k3s-agent
rm -rf /var/lib/rancher/k3s/agent
systemctl start k3s-agent
journalctl -u k3s-agent -n 10 --no-pager
```

### Reboot a worker from AWS CLI
```bash
aws ec2 reboot-instances --instance-ids <instance-id> --region eu-north-1
```

## Recover from a Dead Backend Pod
Kubernetes automatically restarts crashed pods. To manually force restart:
```bash
kubectl rollout restart deployment/backend -n taskapp
```

## Recover from a Bad Migration
```bash
# Delete the failed job
kubectl delete job taskapp-migrate -n taskapp
# Fix the migration code and push to git
# Argo CD will recreate the job with the fix
```

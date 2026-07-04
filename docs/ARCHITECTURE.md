# Architecture

## Node Topology

3-node k3s cluster on AWS EC2 (eu-north-1a):

| Node | Role | Instance | Private IP | Public IP |
|------|------|----------|------------|-----------|
| ip-10-0-1-46 | control-plane | t3.small | 10.0.1.46 | 13.60.6.50 |
| ip-10-0-1-31 | worker-1 | t3.micro | 10.0.1.31 | 51.20.52.253 |
| ip-10-0-1-85 | worker-2 | t3.micro | 10.0.1.85 | 51.20.86.32 |

All nodes share a VPC (10.0.0.0/16) and subnet (10.0.1.0/24).
Overlay network: WireGuard (flannel-backend=wireguard-native, UDP 51820).

## Request Flow

User Browser
     |
     v
DNS: prhurmeeze.name.ng resolves to 13.60.6.50
     |
     v  port 443 -> iptables DNAT -> NodePort 30147
Nginx Ingress Controller
     |
     |-- /api/* -> backend-service:5000 -> Flask/Gunicorn (2-5 pods via HPA)
     |                                          |
     |                                          v
     |                                 postgres:5432 (StatefulSet)
     |                                 PVC: 5Gi gp3 EBS
     |
     |-- /* -> frontend-service:80 -> React/nginx (2 pods)


## GitOps Flow

git push to GitHub (PRHURMEEZE/capstone-phoenix)
     |
     v  Argo CD polls every 3 minutes
Argo CD detects diff
     |
     v
Automated kubectl apply
     |
     v
Kubernetes reconciles desired state


## How Core Requirements Fix Single-Server Assumptions

| Requirement | Single-server problem | Fix |
|-------------|----------------------|-----|
| Postgres StatefulSet + PVC | Pod restart = data loss | PVC persists independently of pod lifecycle |
| 2+ replicas + topologySpread | Server dies = app dies | Pods on different nodes; one dying keeps app up |
| Migration Job (PreSync hook) | 2+ replicas race on migrations | Job runs once before any replica starts |
| RollingUpdate maxUnavailable=0 | Deploy = downtime | New pod ready before old terminates |
| HPA | Manual scaling only | Auto-scales 2-5 replicas on CPU/memory |
| NetworkPolicy | All pods talk to all pods | Postgres only reachable from backend |
| PodDisruptionBudget | Node drain kills all pods | Min 1 replica always available |
| TLS via cert-manager | HTTP only | Let's Encrypt cert auto-renewed every 90 days |

## Network Security

| Port | Protocol | Allowed From | Purpose |
|------|----------|-------------|---------|
| 22 | TCP | 0.0.0.0/0 | SSH operator access |
| 80 | TCP | 0.0.0.0/0 | HTTP ingress |
| 443 | TCP | 0.0.0.0/0 | HTTPS ingress |
| 6443 | TCP | cluster only | k3s API server |
| 51820 | UDP | cluster only | WireGuard overlay |
| 10250 | TCP | cluster only | kubelet metrics |

## Storage

- Postgres PVC: 5Gi gp3 EBS (ReadWriteOnce)
- Storage class: local-path (k3s default)
- Data survives pod deletion proven by killing postgres-0 and verifying data intact after reschedule

## Component Versions

- k3s: v1.36.2+k3s1
- Postgres: 15
- Argo CD: stable channel
- cert-manager: v1.14.0
- ingress-nginx: controller-v1.10.1

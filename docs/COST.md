# Cost Analysis

## Monthly Cost (eu-north-1)

| Resource | Type | Count | Unit Cost | Monthly |
|----------|------|-------|-----------|---------|
| Control Plane EC2 | t3.small | 1 | $0.023/hr | ~$17 |
| Worker EC2 | t3.micro | 2 | $0.012/hr | ~$17 |
| EBS Volumes (20GB gp3) | gp3 | 3 | $0.096/GB | ~$6 |
| S3 (tfstate) | Standard | 1 | ~$0.023/GB | <$1 |
| DynamoDB (lock table) | On-demand | 1 | Pay per request | <$1 |
| Data Transfer | Outbound | - | $0.09/GB | ~$2 |
| **Total** | | | | **~$43/month** |

## How to Cut Cost in Half

Switch all three nodes to **Spot Instances** — AWS Spot pricing for t3.small and t3.micro in eu-north-1 is typically 60-70% cheaper than On-Demand, bringing the total to approximately $15-18/month. To handle Spot interruptions, use a mixed instance policy with On-Demand for the control plane only (since losing it disrupts the entire cluster) and Spot for workers (where k3s will reschedule pods automatically within seconds). Alternatively, deploy during off-peak hours only and use `terraform destroy` when not in use, reducing cost to near zero for a capstone project that only needs to be live during grading.

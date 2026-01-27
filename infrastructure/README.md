# Infrastructure

Provision a Kubernetes cluster on [Rackspace Spot](https://spot.rackspace.com) using OpenTofu/Terraform.

## What Gets Created

| Resource   | Configuration |
|------------|---------------|
| Cloudspace | Single control plane, Calico CNI, `us-central-dfw-1` |
| Node Pool  | `gp.vs1.xlarge-dfw` spot instances, 3-5 nodes (autoscaling) |
| Budget     | ~$10/day across all nodes |

## Setup

1. Get an [API token](https://spot.rackspace.com/docs/en/deploy-your-cloudspace-via-terraform#obtain-the-access-token-from-the-spot-user-interface)

2. Deploy:
   ```bash
   export TF_VAR_rackspace_spot_token='<your_token>'
   tofu init
   tofu plan
   tofu apply
   ```

3. Connect to cluster:
   ```bash
   tofu output -raw kubeconfig > ~/.kube/config
   kubectl get nodes
   ```

## Cleanup

```bash
tofu destroy
```

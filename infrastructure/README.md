# Infrastructure

Provision a Kubernetes cluster on [Rackspace Spot](https://spot.rackspace.com) using OpenTofu/Terraform.

## What Gets Created

| Resource   | Description |
|------------|-------------|
| Cloudspace | Single control plane, Calico CNI, Gen-2 datacenter (`us-central-dfw-2`) |
| Node Pool  | Gen-2 General Purpose spot instances, autoscaling (min 3 nodes for HA) |

## Budget-Based Server Selection

The infrastructure automatically selects the optimal server class based on your monthly budget.

### How It Works

1. **Candidate Classes**: Gen-2 General Purpose virtual servers (`gp.vs2.*-dfw2`)
2. **Constraints**:
   - Minimum 3 nodes (required for HA workloads)
   - Bid price must meet or exceed the class minimum
3. **Selection**: Choose the largest server class (most vCPUs per node) that meets HA requirements

This approach favors larger nodes over more smaller nodes, which is better for workloads like UDS Core where components benefit from more memory and CPU per node.

### Server Classes (as of January 2026)

| Class | vCPUs | Memory | Min Bid ($/hr) |
|-------|-------|--------|----------------|
| `gp.vs2.medium-dfw2` | 2 | 3.75 GB | $0.01 |
| `gp.vs2.large-dfw2` | 4 | 15 GB | $0.04 |
| `gp.vs2.xlarge-dfw2` | 8 | 30 GB | $0.08 |
| `gp.vs2.2xlarge-dfw2` | 16 | 60 GB | $0.15 |

For current pricing, see the [Rackspace Spot documentation](https://spot.rackspace.com/docs/en/cloud-servers).

## Setup

1. Get an [API token](https://spot.rackspace.com/docs/en/deploy-your-cloudspace-via-terraform#obtain-the-access-token-from-the-spot-user-interface)

2. Deploy:
   ```bash
   export TF_VAR_rackspace_spot_token='<your_token>'
   tofu init
   tofu plan
   tofu apply
   ```

3. Customize budget (optional):
   ```bash
   tofu apply -var="monthly_budget_usd=100"
   ```

4. Connect to cluster:
   ```bash
   tofu output -raw kubeconfig > ~/.kube/config
   kubectl get nodes
   ```

## Cleanup

```bash
tofu destroy
```

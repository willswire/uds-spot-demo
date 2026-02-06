# Infrastructure

Provision a Kubernetes cluster on [Rackspace Spot](https://spot.rackspace.com) using OpenTofu/Terraform.

## What Gets Created

| Resource   | Description |
|------------|-------------|
| Cloudspace | Single control plane, Calico CNI, Gen-2 datacenter (`us-central-dfw-2`) |
| Node Pool  | Gen-2 General Purpose spot instances, fixed 3 nodes for HA |

## Budget-Based Server Selection

The infrastructure automatically selects the optimal server class based on your daily budget (default: $10 USD/day).

### How It Works

1. **Candidate Classes**: Gen-2 General Purpose virtual servers (`gp.vs2.*-dfw2`)
2. **Constraints**:
   - Fixed 3 nodes (required for HA workloads)
   - Bid price must meet or exceed current market price
3. **Selection**: Chooses the largest server class (most vCPUs per node) affordable within budget

This approach favors larger nodes over many smaller nodes, which benefits workloads like UDS Core where components require more memory and CPU per node.

### Server Classes (as of January 2026)

| Class | vCPUs | Memory | Min Bid |
|-------|-------|--------|---------|
| `gp.vs2.large-dfw2` | 4 | 15 GB | $0.04/hr |
| `gp.vs2.xlarge-dfw2` | 8 | 30 GB | $0.08/hr |
| `gp.vs2.2xlarge-dfw2` | 16 | 60 GB | $0.15/hr |

Market prices fluctuate and may exceed minimum bids. The required budget depends on current market conditions. For current pricing, see the [Rackspace Spot documentation](https://spot.rackspace.com/docs/en/cloud-servers).

## Setup

1. Obtain an [API token](https://spot.rackspace.com/docs/en/deploy-your-cloudspace-via-terraform#obtain-the-access-token-from-the-spot-user-interface)

2. Deploy:
   ```bash
   export TF_VAR_rackspace_spot_token='<your_token>'
   tofu init
   tofu plan
   tofu apply
   ```

3. Customize budget (optional):
   ```bash
   tofu apply -var="daily_budget_usd=15"
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

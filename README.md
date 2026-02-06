# UDS Spot Demo

Deploy [UDS Core](https://github.com/defenseunicorns/uds-core) on [Rackspace Spot](https://spot.rackspace.com) infrastructure.

## Overview

This project provisions a Kubernetes cluster on Rackspace Spot and deploys a UDS bundle with:

- **Istio** - Service mesh with admin/tenant gateways
- **Keycloak** - Identity and access management (Google IDP)
- **Loki + Grafana** - Logging and observability
- **Velero** - Backup with MinIO storage
- **Falco** - Runtime security monitoring
- **Pepr** - Policy engine and admission control

## Prerequisites

- [UDS CLI](https://github.com/defenseunicorns/uds-cli)
- [OpenTofu](https://opentofu.org/) or Terraform
- Rackspace Spot account with [API token](https://spot.rackspace.com/docs/en/deploy-your-cloudspace-via-terraform#obtain-the-access-token-from-the-spot-user-interface)

## Infrastructure

The infrastructure layer automatically selects the optimal Gen-2 server class based on your daily budget (default: $10 USD/day). It chooses the largest server class affordable at current market prices while maintaining 3 nodes for HA. See [infrastructure/README.md](infrastructure/README.md) for details.

## Quick Start

### 1. Provision Infrastructure

See [infrastructure/README.md](infrastructure/README.md) for cluster setup.

### 2. Deploy UDS

```sh
# Initialize Zarf with registry proxy
uds zarf init \
  --architecture=amd64 \
  --features=registry-proxy=true \
  --registry-mode=proxy \
  --confirm

# Create the bundle (or use pre-built artifact)
uds create --architecture=amd64 --confirm

# Deploy the bundle
uds deploy uds-bundle-uds-spot-demo-amd64-0.1.0.tar.zst \
  --architecture=amd64 \
  --confirm
```

## Configuration

Bundle variables can be customized for:

- TLS certificates (admin/tenant gateways)
- S3-compatible storage endpoints (Loki, Velero)
- Keycloak database connection
- Resource requests/limits

See `uds-bundle.yaml` for all available overrides.

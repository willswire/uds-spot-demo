locals {
  # Gen-2 General Purpose minimum bid prices (from Rackspace Spot docs)
  # https://spot.rackspace.com/docs/en/cloud-servers
  min_bid_prices = {
    "gp.vs2.large-dfw2"   = 0.04
    "gp.vs2.xlarge-dfw2"  = 0.08
    "gp.vs2.2xlarge-dfw2" = 0.15
  }

  # For each class, get specs and calculate effective hourly rate
  class_configs = {
    for name, sc in data.spot_serverclass.candidates : name => {
      server_class = name
      hourly_rate  = max(local.min_bid_prices[name], tonumber(sc.status.spot_pricing.market_price_per_hour))
      vcpus        = tonumber(sc.resources.cpu)
    }
  }

  # Filter to classes affordable within daily budget (24 hrs × 3 nodes for HA)
  hours_per_day = 24
  node_count    = 3
  valid_configs = {
    for name, cfg in local.class_configs : name => cfg
    if var.daily_budget_usd >= cfg.hourly_rate * local.hours_per_day * local.node_count
  }

  # Select the largest class (by vCPUs) we can afford
  selected = length(local.valid_configs) > 0 ? [
    for cfg in values(local.valid_configs) : cfg
    if cfg.vcpus == max([for c in values(local.valid_configs) : c.vcpus]...)
  ][0] : null

  # For error message: find cheapest option
  cheapest_class = [for name, cfg in local.class_configs : name if cfg.hourly_rate == min([for c in values(local.class_configs) : c.hourly_rate]...)][0]
  cheapest_daily = ceil(local.class_configs[local.cheapest_class].hourly_rate * local.hours_per_day * local.node_count)

  # Bid price: round up to nearest 0.005 increment (Rackspace Spot requirement)
  bid_price_step = 0.005
  bid_price      = local.selected != null ? ceil(local.selected.hourly_rate / local.bid_price_step) * local.bid_price_step : 0
}

data "spot_serverclass" "candidates" {
  for_each = local.min_bid_prices
  name     = each.key
}

resource "random_id" "cloudspace_suffix" {
  byte_length = 4
}

resource "spot_cloudspace" "uds" {
  cloudspace_name    = "uds-${random_id.cloudspace_suffix.hex}"
  cni                = "calico"
  region             = "us-central-dfw-2"
  kubernetes_version = "1.33.0"
  hacontrol_plane    = false
  wait_until_ready   = true

  lifecycle {
    precondition {
      condition     = local.selected != null
      error_message = format("Budget of $%d USD/day is insufficient. The cheapest option (%s) requires ~$%d USD/day at current market prices.", var.daily_budget_usd, local.cheapest_class, local.cheapest_daily)
    }
  }
}

resource "spot_spotnodepool" "primary" {
  count                = local.selected != null ? 1 : 0
  cloudspace_name      = resource.spot_cloudspace.uds.cloudspace_name
  server_class         = local.selected.server_class
  bid_price            = format("%.3f", local.bid_price)
  desired_server_count = local.node_count
}

data "spot_kubeconfig" "uds" {
  cloudspace_name = resource.spot_cloudspace.uds.name
}

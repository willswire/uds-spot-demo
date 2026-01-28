locals {
  hours_per_month = 730
  min_nodes       = 3 # Minimum required for HA workloads

  # Minimum budget required: 3 nodes × $0.01/hr × 730 hrs = $21.90
  min_budget = local.min_nodes * 0.01 * local.hours_per_month

  # Gen-2 General Purpose minimum bid prices (from Rackspace Spot docs)
  # https://spot.rackspace.com/docs/en/cloud-servers
  min_bid_prices = {
    "gp.vs2.medium-dfw2"  = 0.01
    "gp.vs2.large-dfw2"   = 0.04
    "gp.vs2.xlarge-dfw2"  = 0.08
    "gp.vs2.2xlarge-dfw2" = 0.15
  }

  # For each class, calculate config with minimum bid price constraint
  class_configs = {
    for name, sc in data.spot_serverclass.candidates : name => {
      server_class  = name
      hourly_rate   = tonumber(sc.status.spot_pricing.market_price_per_hour)
      min_bid_price = local.min_bid_prices[name]
      vcpus         = tonumber(sc.resources.cpu)
      memory_gib    = tonumber(trimsuffix(sc.resources.memory, "GB"))
    }
  }

  # Calculate node counts and filter to valid configs
  # A config is valid if we can afford min_nodes at the minimum bid price
  valid_configs = {
    for name, cfg in local.class_configs : name => merge(cfg, {
      max_nodes = floor(var.monthly_budget_usd / (cfg.min_bid_price * local.hours_per_month))
    }) if floor(var.monthly_budget_usd / (cfg.min_bid_price * local.hours_per_month)) >= local.min_nodes
  }

  # Select the largest server class (by vCPUs per node) that meets HA requirements
  max_vcpus_per_node = length(local.valid_configs) > 0 ? max([for cfg in values(local.valid_configs) : cfg.vcpus]...) : 0
  selected           = length(local.valid_configs) > 0 ? [for cfg in values(local.valid_configs) : cfg if cfg.vcpus == local.max_vcpus_per_node][0] : null

  # Bid price: budget spread across nodes, but at least the minimum
  # Must be a multiple of 0.005 (round down to nearest increment)
  raw_bid_price = max(
    local.selected.min_bid_price,
    var.monthly_budget_usd / local.hours_per_month / local.selected.max_nodes
  )
  bid_price = floor(local.raw_bid_price / 0.005) * 0.005
}

data "spot_serverclass" "candidates" {
  for_each = local.min_bid_prices
  name     = each.key
}

resource "spot_cloudspace" "uds" {
  cloudspace_name  = "uds"
  cni              = "calico"
  region           = "us-central-dfw-2"
  hacontrol_plane  = false
  wait_until_ready = true
}

resource "spot_spotnodepool" "primary" {
  cloudspace_name = resource.spot_cloudspace.uds.cloudspace_name
  server_class    = local.selected.server_class
  bid_price       = format("%.3f", local.bid_price)

  autoscaling = {
    min_nodes = local.min_nodes
    max_nodes = local.selected.max_nodes
  }
}

data "spot_kubeconfig" "uds" {
  cloudspace_name = resource.spot_cloudspace.uds.name
}

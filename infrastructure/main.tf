locals {
  # Budget estimations are subject to change and should be verified before deployment.
  # See https://spot.rackspace.com/docs/en/rackspace-spot-pricing#pricing-summary-resource
  max_nodes          = 5
  hours_per_day      = 24
  daily_budget_usd   = 10
  bid_price_per_node = local.daily_budget_usd / local.hours_per_day / local.max_nodes
}

resource "spot_cloudspace" "uds" {
  cloudspace_name  = "uds"
  cni              = "calico"
  region           = "us-central-dfw-1"
  hacontrol_plane  = false
  wait_until_ready = true
}

resource "spot_spotnodepool" "primary" {
  cloudspace_name = resource.spot_cloudspace.uds.cloudspace_name
  server_class    = "gp.vs1.xlarge-dfw"

  bid_price = format("%.01g", local.bid_price_per_node)

  autoscaling = {
    min_nodes = 3
    max_nodes = local.max_nodes
  }
}

data "spot_kubeconfig" "uds" {
  cloudspace_name = resource.spot_cloudspace.uds.name
}

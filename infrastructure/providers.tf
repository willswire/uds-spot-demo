terraform {
  required_providers {
    spot = {
      source  = "rackerlabs/spot"
      version = "0.1.4"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "spot" {
  token = var.rackspace_spot_token
}

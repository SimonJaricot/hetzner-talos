terraform {
  required_version = ">= 1.9.0"

  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.62"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "~> 0.11"
    }
  }
}

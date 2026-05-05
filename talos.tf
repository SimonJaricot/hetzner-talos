locals {
  cluster_endpoint = "https://${hcloud_load_balancer.controlplane.ipv4}:6443"

  ccm_patch = var.hetzner_ccm_enabled ? yamlencode({
    machine = {
      kubelet = {
        extraArgs = {
          "cloud-provider" = "external"
        }
        nodeIP = {
          validSubnets = [var.subnet_cidr]
        }
      }
    }
  }) : null

  scheduling_patch = var.allow_scheduling_on_controlplanes ? yamlencode({
    cluster = {
      allowSchedulingOnControlPlanes = true
    }
  }) : null

  discovery_patch = var.cluster_discovery_enabled ? null : yamlencode({
    cluster = {
      discovery = {
        enabled = false
      }
    }
  })

  controlplane_patches = compact(concat(
    [local.ccm_patch, local.scheduling_patch, local.discovery_patch],
    var.controlplane_config_patches,
  ))
  worker_patches = compact(concat(
    [local.ccm_patch, local.discovery_patch],
    var.worker_config_patches,
  ))
}

resource "talos_machine_secrets" "this" {
  talos_version = var.talos_version

  lifecycle {
    prevent_destroy = true
  }
}

data "talos_machine_configuration" "controlplane" {
  cluster_name       = var.cluster_name
  machine_type       = "controlplane"
  cluster_endpoint   = local.cluster_endpoint
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  talos_version      = var.talos_version
  config_patches     = local.controlplane_patches
  kubernetes_version = var.kubernetes_version != "" ? var.kubernetes_version : null
}

data "talos_machine_configuration" "worker" {
  cluster_name       = var.cluster_name
  machine_type       = "worker"
  cluster_endpoint   = local.cluster_endpoint
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  talos_version      = var.talos_version
  config_patches     = local.worker_patches
  kubernetes_version = var.kubernetes_version != "" ? var.kubernetes_version : null
}

resource "talos_machine_configuration_apply" "controlplane" {
  count                       = var.controlplane_count
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane.machine_configuration
  node                        = hcloud_server.controlplane[count.index].ipv4_address

  depends_on = [
    hcloud_server_network.controlplane,
    hcloud_firewall_attachment.this,
  ]
}

resource "talos_machine_configuration_apply" "worker" {
  count                       = var.worker_count
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker.machine_configuration
  node                        = hcloud_server.worker[count.index].ipv4_address

  depends_on = [
    hcloud_server_network.worker,
    hcloud_firewall_attachment.this,
  ]
}

resource "talos_machine_bootstrap" "this" {
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = hcloud_server.controlplane[0].ipv4_address

  depends_on = [talos_machine_configuration_apply.controlplane]

  lifecycle {
    ignore_changes = all
  }
}

data "talos_cluster_kubeconfig" "this" {
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = hcloud_server.controlplane[0].ipv4_address

  depends_on = [talos_machine_bootstrap.this]
}

data "talos_client_configuration" "this" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  nodes                = [for s in hcloud_server.controlplane : s.ipv4_address]
  endpoints            = [hcloud_load_balancer.controlplane.ipv4]
}

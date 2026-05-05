data "hcloud_ssh_key" "this" {
  name = var.ssh_key_name
}

resource "hcloud_placement_group" "controlplane" {
  name = "${var.cluster_name}-controlplane"
  type = "spread"
}

resource "hcloud_placement_group" "worker" {
  name = "${var.cluster_name}-worker"
  type = "spread"
}

resource "hcloud_server" "controlplane" {
  count              = var.controlplane_count
  name               = "${var.cluster_name}-cp-${count.index + 1}"
  server_type        = var.controlplane_server_type
  image              = var.talos_image_id
  location           = var.location
  placement_group_id = hcloud_placement_group.controlplane.id
  ssh_keys           = [data.hcloud_ssh_key.this.id]

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }

  labels = {
    cluster = var.cluster_name
    role    = "controlplane"
  }

  lifecycle {
    ignore_changes = [image, ssh_keys, user_data]
  }
}

resource "hcloud_server_network" "controlplane" {
  count     = var.controlplane_count
  server_id = hcloud_server.controlplane[count.index].id
  subnet_id = hcloud_network_subnet.this.id
}

resource "hcloud_server" "worker" {
  count              = var.worker_count
  name               = "${var.cluster_name}-worker-${count.index + 1}"
  server_type        = var.worker_server_type
  image              = var.talos_image_id
  location           = var.location
  placement_group_id = hcloud_placement_group.worker.id
  ssh_keys           = [data.hcloud_ssh_key.this.id]

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }

  labels = {
    cluster = var.cluster_name
    role    = "worker"
  }

  lifecycle {
    ignore_changes = [image, ssh_keys, user_data]
  }
}

resource "hcloud_server_network" "worker" {
  count     = var.worker_count
  server_id = hcloud_server.worker[count.index].id
  subnet_id = hcloud_network_subnet.this.id
}

resource "hcloud_load_balancer" "controlplane" {
  name               = "${var.cluster_name}-controlplane"
  load_balancer_type = var.lb_type
  location           = var.location

  algorithm {
    type = "round_robin"
  }

  labels = {
    cluster = var.cluster_name
  }
}

resource "hcloud_load_balancer_network" "controlplane" {
  load_balancer_id = hcloud_load_balancer.controlplane.id
  subnet_id        = hcloud_network_subnet.this.id
}

resource "hcloud_load_balancer_service" "kube_api" {
  load_balancer_id = hcloud_load_balancer.controlplane.id
  protocol         = "tcp"
  listen_port      = 6443
  destination_port = 6443

  health_check {
    protocol = "tcp"
    port     = 6443
    interval = 15
    timeout  = 10
    retries  = 3
  }
}

resource "hcloud_load_balancer_target" "controlplane" {
  count            = var.controlplane_count
  type             = "server"
  load_balancer_id = hcloud_load_balancer.controlplane.id
  server_id        = hcloud_server.controlplane[count.index].id
  use_private_ip   = true

  depends_on = [
    hcloud_load_balancer_network.controlplane,
    hcloud_server_network.controlplane,
  ]
}

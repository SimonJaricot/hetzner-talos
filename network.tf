resource "hcloud_network" "this" {
  name     = var.cluster_name
  ip_range = var.network_cidr
}

resource "hcloud_network_subnet" "this" {
  network_id   = hcloud_network.this.id
  type         = "cloud"
  network_zone = var.network_zone
  ip_range     = var.subnet_cidr
}

resource "hcloud_firewall" "this" {
  name = var.cluster_name

  # Kubernetes API server
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "6443"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  # Talos API — restrict to operator CIDRs in production via talos_api_allowed_cidrs
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "50000"
    source_ips = var.talos_api_allowed_cidrs
  }

  # ICMP
  rule {
    direction  = "in"
    protocol   = "icmp"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  # Internal cluster traffic (all protocols within private network)
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "any"
    source_ips = [var.network_cidr]
  }

  rule {
    direction  = "in"
    protocol   = "udp"
    port       = "any"
    source_ips = [var.network_cidr]
  }
}

resource "hcloud_firewall_attachment" "this" {
  firewall_id    = hcloud_firewall.this.id
  label_selector = "cluster=${var.cluster_name}"

  depends_on = [
    hcloud_server.controlplane,
    hcloud_server.worker,
  ]
}

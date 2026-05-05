output "cluster_endpoint" {
  description = "Kubernetes API endpoint (via load balancer)"
  value       = local.cluster_endpoint
}

output "load_balancer_ip" {
  description = "Public IPv4 of the control plane load balancer (use for DNS records)"
  value       = hcloud_load_balancer.controlplane.ipv4
}

output "network_id" {
  description = "Hetzner private network ID (use to attach additional resources)"
  value       = hcloud_network.this.id
}

output "subnet_id" {
  description = "Hetzner private subnet ID"
  value       = hcloud_network_subnet.this.id
}

output "controlplane_ips" {
  description = "Public IPv4 addresses of control plane nodes"
  value       = [for s in hcloud_server.controlplane : s.ipv4_address]
}

output "worker_ips" {
  description = "Public IPv4 addresses of worker nodes"
  value       = [for s in hcloud_server.worker : s.ipv4_address]
}

output "talosconfig" {
  description = "Talos client configuration (talosconfig) — save to ~/.talos/config"
  value       = data.talos_client_configuration.this.talos_config
  sensitive   = true
}

output "kubeconfig" {
  description = "Kubernetes client configuration (kubeconfig) — server is load_balancer_ip:6443"
  value       = data.talos_cluster_kubeconfig.this.kubeconfig_raw
  sensitive   = true
}

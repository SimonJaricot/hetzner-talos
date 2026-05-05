output "cluster_endpoint" {
  description = "Kubernetes API endpoint (via load balancer)"
  value       = local.cluster_endpoint
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
  description = "Talos client configuration (talosconfig)"
  value       = data.talos_client_configuration.this.talos_config
  sensitive   = true
}

output "kubeconfig" {
  description = "Kubernetes client configuration (kubeconfig)"
  value       = data.talos_cluster_kubeconfig.this.kubeconfig_raw
  sensitive   = true
}

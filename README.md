# hetzner-talos

Reusable Terraform module for deploying a Talos Linux Kubernetes cluster on Hetzner Cloud.

Provisions: private network, firewall, spread placement group, control plane servers, worker servers, and an `lb11` load balancer for the HA control plane endpoint. Generates and applies Talos machine configs, bootstraps etcd, and outputs `kubeconfig` + `talosconfig`.

## Requirements

- Talos snapshot already uploaded to Hetzner (see `scripts/upload-talos-image.sh`)
- `hcloud_token` available to the provider
- Existing SSH key in Hetzner Cloud (emergency console access only — Talos has no SSH)

## Usage

```hcl
module "talos" {
  source = "git::https://github.com/SimonJaricot/hetzner-talos.git"

  cluster_name   = "prod"
  talos_image_id = "381684116"   # output of upload-talos-image.sh
  ssh_key_name   = "my-key"
}
```

Retrieve credentials after apply:

```bash
terraform output -raw talosconfig > ~/.talos/config
terraform output -raw kubeconfig > ~/.kube/config
kubectl get nodes
```

## Variables

| Name | Description | Default |
|------|-------------|---------|
| `cluster_name` | Cluster name (used as resource prefix) | required |
| `talos_image_id` | Hetzner snapshot ID of the Talos image | required |
| `ssh_key_name` | Existing Hetzner SSH key name | required |
| `controlplane_count` | Number of control plane nodes | `3` |
| `worker_count` | Number of worker nodes | `2` |
| `controlplane_server_type` | Server type for control planes | `cx22` |
| `worker_server_type` | Server type for workers | `cx22` |
| `location` | Hetzner datacenter | `nbg1` |
| `network_zone` | Hetzner network zone | `eu-central` |
| `network_cidr` | Private network CIDR | `10.0.0.0/8` |
| `subnet_cidr` | Subnet CIDR (within network_cidr) | `10.0.0.0/16` |
| `hetzner_ccm_enabled` | Patch kubelet with `cloud-provider=external` for CCM | `true` |
| `controlplane_config_patches` | Extra Talos YAML patches for control planes | `[]` |
| `worker_config_patches` | Extra Talos YAML patches for workers | `[]` |
| `kubernetes_version` | Kubernetes version override (empty = Talos default) | `""` |

## Outputs

| Name | Description |
|------|-------------|
| `cluster_endpoint` | Kubernetes API URL via load balancer |
| `controlplane_ips` | Public IPs of control plane nodes |
| `worker_ips` | Public IPs of worker nodes |
| `talosconfig` | talosctl client config (sensitive) |
| `kubeconfig` | kubectl client config (sensitive) |

## Architecture

```
                    ┌─────────────────┐
                    │  lb11 (6443)    │  ← cluster_endpoint
                    └────────┬────────┘
                             │ private net
          ┌──────────────────┼──────────────────┐
          │                  │                  │
   ┌──────┴──────┐  ┌────────┴────┐  ┌──────────┴──┐
   │  cp-1 (cx22)│  │ cp-2 (cx22) │  │ cp-3 (cx22) │  spread placement group
   └─────────────┘  └─────────────┘  └─────────────┘
   ┌─────────────┐  ┌─────────────┐
   │worker-1     │  │ worker-2    │
   └─────────────┘  └─────────────┘
          └──────────────────────────────────────────┘
                    hcloud_network (10.0.0.0/8)
```

## Notes

- Control planes are spread across physical hosts via `hcloud_placement_group` (type `spread`)
- Firewall allows TCP 6443 + 50000 from anywhere; all traffic within private network
- `talos_machine_configuration_apply` runs at `terraform apply` time — nodes must be reachable on port 50000
- After destroying and recreating the cluster, run `terraform apply` twice if LB IP changes (first apply creates LB, second regenerates machine configs with new IP)

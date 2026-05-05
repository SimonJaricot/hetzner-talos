variable "cluster_name" {
  description = "Name of the Talos cluster (lowercase alphanumeric + hyphens)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{0,61}[a-z0-9]$", var.cluster_name))
    error_message = "cluster_name must be lowercase alphanumeric with hyphens, 2-63 chars."
  }
}

variable "talos_image_id" {
  description = "Hetzner snapshot ID of the Talos image (created by scripts/upload-talos-image.sh)"
  type        = string
}

variable "talos_version" {
  description = "Talos version string matching the snapshot (e.g. v1.13.0) — pins machine config generation"
  type        = string
  default     = "v1.13.0"
}

variable "ssh_key_name" {
  description = "Name of existing SSH key in Hetzner Cloud (attached for emergency console access)"
  type        = string
}

variable "controlplane_count" {
  description = "Number of control plane nodes — must be odd for etcd quorum (1, 3, 5)"
  type        = number
  default     = 3

  validation {
    condition     = var.controlplane_count % 2 == 1 && var.controlplane_count >= 1
    error_message = "controlplane_count must be an odd number >= 1 (e.g. 1, 3, 5) for etcd quorum."
  }
}

variable "worker_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 2
}

variable "controlplane_server_type" {
  description = "Hetzner server type for control plane nodes"
  type        = string
  default     = "cx22"
}

variable "worker_server_type" {
  description = "Hetzner server type for worker nodes"
  type        = string
  default     = "cx22"
}

variable "lb_type" {
  description = "Hetzner load balancer type for the control plane endpoint"
  type        = string
  default     = "lb11"
}

variable "location" {
  description = "Hetzner datacenter location"
  type        = string
  default     = "nbg1"

  validation {
    condition     = contains(["nbg1", "fsn1", "hel1", "ash", "hil", "sin"], var.location)
    error_message = "Must be a valid Hetzner location: nbg1, fsn1, hel1, ash, hil, sin."
  }
}

variable "network_zone" {
  description = "Hetzner network zone matching the location"
  type        = string
  default     = "eu-central"

  validation {
    condition     = contains(["eu-central", "us-east", "us-west", "ap-southeast"], var.network_zone)
    error_message = "Must be one of: eu-central, us-east, us-west, ap-southeast."
  }
}

variable "network_cidr" {
  description = "CIDR for the private network — avoid 10.96.0.0/12 (svc) and 10.244.0.0/16 (pod) defaults"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR for the private subnet (must be within network_cidr)"
  type        = string
  default     = "10.0.1.0/24"
}

variable "talos_api_allowed_cidrs" {
  description = "CIDRs allowed to reach Talos API (port 50000) — restrict to operator IPs in production"
  type        = list(string)
  default     = ["0.0.0.0/0", "::/0"]
}

variable "hetzner_ccm_enabled" {
  description = "Patch kubelet with cloud-provider=external and nodeIP.validSubnets for hcloud-cloud-controller-manager. NOTE: the CCM Helm chart + hcloud token secret in kube-system must be deployed separately."
  type        = bool
  default     = true
}

variable "allow_scheduling_on_controlplanes" {
  description = "Allow workloads to be scheduled on control plane nodes (useful for single-node or small clusters)"
  type        = bool
  default     = false
}

variable "cluster_discovery_enabled" {
  description = "Enable Talos cluster discovery service (talos.dev registry) — disable in air-gapped or production environments"
  type        = bool
  default     = false
}

variable "controlplane_config_patches" {
  description = "Additional Talos machine config patches (YAML strings) for control plane nodes"
  type        = list(string)
  default     = []
}

variable "worker_config_patches" {
  description = "Additional Talos machine config patches (YAML strings) for worker nodes"
  type        = list(string)
  default     = []
}

variable "kubernetes_version" {
  description = "Kubernetes version to install (empty = Talos default for this release)"
  type        = string
  default     = ""
}

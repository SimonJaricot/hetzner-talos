variable "cluster_name" {
  description = "Name of the Talos cluster"
  type        = string
}

variable "talos_image_id" {
  description = "Hetzner snapshot ID of the Talos image (created by scripts/upload-talos-image.sh)"
  type        = string
}

variable "ssh_key_name" {
  description = "Name of existing SSH key in Hetzner Cloud (attached for emergency console access)"
  type        = string
}

variable "controlplane_count" {
  description = "Number of control plane nodes (use 3 for HA)"
  type        = number
  default     = 3
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

variable "location" {
  description = "Hetzner datacenter location"
  type        = string
  default     = "nbg1"
}

variable "network_zone" {
  description = "Hetzner network zone (eu-central, us-east, us-west, ap-southeast)"
  type        = string
  default     = "eu-central"
}

variable "network_cidr" {
  description = "CIDR for the private network"
  type        = string
  default     = "10.0.0.0/8"
}

variable "subnet_cidr" {
  description = "CIDR for the private subnet (must be within network_cidr)"
  type        = string
  default     = "10.0.0.0/16"
}

variable "hetzner_ccm_enabled" {
  description = "Add kubelet cloud-provider=external patch required by hcloud-cloud-controller-manager"
  type        = bool
  default     = true
}

variable "controlplane_config_patches" {
  description = "List of Talos machine config patches (YAML strings) to apply to control plane nodes"
  type        = list(string)
  default     = []
}

variable "worker_config_patches" {
  description = "List of Talos machine config patches (YAML strings) to apply to worker nodes"
  type        = list(string)
  default     = []
}

variable "kubernetes_version" {
  description = "Kubernetes version to install (empty = Talos default for this release)"
  type        = string
  default     = ""
}

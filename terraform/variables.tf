# Variables
variable "vm_count" {
  default = 2  # Number of worker nodes
}

variable "proxmox_node" {
  default = "pve"
}

variable "vm_template" {
  default = "ubuntu-22.04-template"
}

variable "vm_template_id" {
  default = 9000
}

variable "vm_network" {
  default = "vmbr0"
}

variable "vm_gateway" {
  default = "192.168.1.1"
}

variable "virtual_environment_endpoint" {
  type        = string
  description = "The endpoint for the Proxmox Virtual Environment API (example: https://host:port)"
}

variable "virtual_environment_api_username" {
  type        = string
  description = "The API username for the Proxmox Virtual Environment API"
}

variable "virtual_environment_api_password" {
  type        = string
  description = "The API password for the Proxmox Virtual Environment API"
}

variable "virtual_environment_ssh_username" {
  type        = string
  description = "The username for the Proxmox Virtual Environment API"
}
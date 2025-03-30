terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">=0.73.2"
    }
  }
}

provider "proxmox" {
  endpoint = var.virtual_environment_endpoint
  username = var.virtual_environment_api_username
  password = var.virtual_environment_api_password
  insecure = true
}

locals {
  datastore_id = "local-lvm"
}

# Master Node
resource "proxmox_virtual_environment_vm" "master" {
  name      = "k8s-master"
  node_name = var.proxmox_node
  stop_on_destroy = true

  clone {
    vm_id = var.vm_template_id
  }

  cpu {
    cores = 1
    sockets = 1
    limit = 64
  }

  memory {
    dedicated = 6144
  }

  disk {
    datastore_id = local.datastore_id
    size         = 20
    interface    = "scsi0"
  }

  initialization {
    datastore_id = local.datastore_id
    interface    = "scsi4"
    ip_config {
      ipv4 {
        address = "192.168.1.100/24"
        gateway = var.vm_gateway
      }
    }
    user_account {
      username = var.virtual_environment_ssh_username
      password = var.virtual_environment_ssh_username
      keys     = [tls_private_key.ssh_key.public_key_openssh]
    }
  }

  network_device {
    bridge = var.vm_network
  }

  connection {
    type        = "ssh"
    host        = element(element(self.ipv4_addresses, index(self.network_interface_names, "eth0")), 0)
    private_key = tls_private_key.ssh_key.private_key_pem
    user        = var.virtual_environment_ssh_username
    password    = var.virtual_environment_ssh_username
  }


  provisioner "remote-exec" {
    inline = [
      "echo Welcome to $(hostname)!",
    ]
  }
}

# Worker Nodes
resource "proxmox_virtual_environment_vm" "workers" {
  count      = var.vm_count
  name       = "k8s-worker-${count.index + 1}"
  stop_on_destroy = true
  node_name  = var.proxmox_node

  clone {
    vm_id = var.vm_template_id
  }

  cpu {
    cores = 1
    sockets = 1
    limit = 64
  }

  memory {
    dedicated = 4096
  }

  disk {
    datastore_id = local.datastore_id
    size         = 20
    interface    = "scsi0"
  }

  initialization {
    datastore_id = local.datastore_id
    interface    = "scsi4"
    ip_config {
      ipv4 {
        address = "192.168.1.10${count.index + 1}/24"
        gateway = var.vm_gateway
      }
    }
    user_account {
      username = var.virtual_environment_ssh_username
      password = var.virtual_environment_ssh_username
      keys     = [tls_private_key.ssh_key.public_key_openssh]
    }
  }

  network_device {
    bridge = var.vm_network
  }

  connection {
    type        = "ssh"
    host        = element(element(self.ipv4_addresses, index(self.network_interface_names, "eth0")), 0)
    private_key = tls_private_key.ssh_key.private_key_pem
    user        = var.virtual_environment_ssh_username
    password    = var.virtual_environment_ssh_username
  }

  provisioner "remote-exec" {
    inline = [
      "echo Welcome to $(hostname)!",
    ]
  }
}

output "master_vm_id" {
  value = proxmox_virtual_environment_vm.master.id
}

output "worker_vm_ids" {
  value = [for worker in proxmox_virtual_environment_vm.workers : worker.id]
}

output "worker_ipv4_addresses" {
  value = [for worker in proxmox_virtual_environment_vm.workers : worker.ipv4_addresses]
}

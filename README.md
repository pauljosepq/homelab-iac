# Homelab Setup with K3s, Terraform, Ansible, and Proxmox

## Overview
This guide covers how to build a homelab from scratch using Proxmox as the hypervisor, Terraform for infrastructure automation, Ansible for configuration management, and K3s as the lightweight Kubernetes distribution.

## Prerequisites
- A server or a machine capable of running Proxmox VE.
- Basic knowledge of Linux, networking, and automation tools.
- Installed software:
  - [Proxmox VE](https://www.proxmox.com/en/proxmox-ve)
  - [Terraform](https://developer.hashicorp.com/terraform/downloads)
  - [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
  - [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)

## Architecture
1. **Proxmox**: Hypervisor hosting virtual machines (VMs) for the cluster.
2. **Terraform**: Automates VM creation and network setup.
3. **Ansible**: Configures the VMs, installs K3s, and sets up the cluster.
4. **K3s**: Lightweight Kubernetes cluster running workloads.

## Repository Structure
```
📂 homelab-k3s
├── 📂 ansible
│   ├── inventory.yml            # Ansible inventory file
├── 📂 terraform
│   ├── main.tf                  # Terraform configuration
│   ├── ssh.tf                   # SSH configuration for Terraform
│   ├── terraform.tfvars         # Terraform variables
│   ├── variables.tf             # Terraform variable definitions
├── .gitignore                   # Git ignore file
├── README                       # Documentation
├── vm-template.sh               # Script for VM templating
```

## Step-by-Step Setup

### Step 1: Set Up Proxmox
1. Install Proxmox VE on your server.
2. Configure networking and storage.
3. Create an API user for automation:
   ```bash
   pveum user add terraform@pam --password YOUR_PASSWORD
   pveum aclmod / -user terraform@pam -role Administrator
   ```

   Note: Proxmox allows API Tokens ussage, but cannot be used with Terraform provider bpg/proxmox
4. Create a VM template using vm-template.sh.

    When asked to configure cloud init, you can use this as an example:

    - **User**: `ubuntu`
    - **Password**: (Set your preferred password)
    - **DNS domain**: `use host settings`
    - **DNS servers**: `use host settings`
    - **SSH public key**: (You can use Proxmox public key located in `/root/.ssh/id_rsa.pub`) 
    - **Upgrade packages**: `Yes`
    - **IP Config (net0)**: `ip=dhcp`

    Once these settings are configured, you can proceed with converting the VM to a template.


### Step 2: Configure Terraform for Proxmox
You can do the terraform/ansible installation in any PC in the same network.

1. Install the Proxmox Terraform provider:
   ```bash
   terraform init
   ```
2. Define your infrastructure in `main.tf`, `ssh.tf`, and `variables.tf`.
3. Apply the configuration:
   ```bash
   terraform apply
   ```

Before continuing to the next step, make sure you can `ssh` into your VMs from your PC.

### Step 3: Configure Ansible for K3s Deployment
1. Configure the inventory file `inventory.yml`.
2. Use Ansible Galaxy template `install_k3s.yaml`:
   ```bash
   ansible-galaxy collection install git+https://github.com/k3s-io/k3s-ansible.git
   ```
3. Run the playbook:
   ```bash
   ansible-playbook k3s.orchestration.site -i ansible/inventory.yml
   ```

### Step 4: Verify the Cluster
1. Check node status:
   ```bash
   kubectl get nodes
   ```

## Conclusion
Following this guide, you now have a fully automated homelab running K3s on Proxmox, managed with Terraform and Ansible. Happy homelabbing!


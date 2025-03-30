#!/bin/bash

set -e
set -o pipefail

# Variables
IMG_URL="https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64-disk-kvm.img" # User kvm images
IMG_NAME="jammy-server-cloudimg-amd64-disk-kvm.img"
VM_ID=9000
VM_NAME="ubuntu-22.04-template"
STORAGE_POOL="local-lvm"

# Function to check command success
check_command() {
    if [ $? -ne 0 ]; then
        echo "Error: $1 failed. Exiting."
        exit 1
    fi
}

# Download Ubuntu 22.04 LTS Minimal Cloud Image
if [ ! -f "$IMG_NAME" ]; then
    echo "Downloading Ubuntu Cloud Image..."
    wget "$IMG_URL" -O "$IMG_NAME"
    check_command "Downloading Ubuntu Cloud Image"
else
    echo "Ubuntu Cloud Image already exists, skipping download."
fi

# Install qemu-guest-agent in the image
echo "Installing qemu-guest-agent in the image..."
sudo virt-customize -a "$IMG_NAME" --install qemu-guest-agent
check_command "Installing qemu-guest-agent"

# Create Proxmox VM (without booting)
echo "Creating Proxmox VM..."
qm create "$VM_ID" --name "$VM_NAME" --memory 4096 --cores 2 --net0 virtio,bridge=vmbr0
check_command "Creating Proxmox VM"

# Import disk
echo "Importing disk..."
qm importdisk "$VM_ID" "$IMG_NAME" "$STORAGE_POOL"
check_command "Importing disk"

# Attach disk to VM
echo "Attaching disk to VM..."
qm set "$VM_ID" --scsihw virtio-scsi-pci --scsi0 "$STORAGE_POOL":vm-"$VM_ID"-disk-0
check_command "Attaching disk to VM"

# Enable cloud-init
echo "Configuring cloud-init..."
qm set "$VM_ID" --ide2 "$STORAGE_POOL":cloudinit
qm set "$VM_ID" --boot c --bootdisk scsi0
qm set "$VM_ID" --serial0 socket --vga serial0
qm set "$VM_ID" --agent enabled=1
check_command "Configuring cloud-init"

while true; do
    echo "Have you configured cloud-init for this VM? (yes/no)"
    read CONFIRM
    if [[ "$CONFIRM" == "yes" ]]; then
        break
    fi
    echo "Please configure cloud-init before proceeding."
done

# Convert to template
echo "Converting VM to template..."
qm template "$VM_ID"
check_command "Converting VM to template"

echo "VM template setup completed successfully."

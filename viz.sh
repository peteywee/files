#!/bin/bash
# KVM and LXD Setup Script

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

log() { echo -e "${GREEN}[SETUP]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Check if running as root
[[ $EUID -ne 0 ]] && error "Please run as root"

# Install KVM and related tools
log "Installing KVM and related packages..."
apt-get update
apt-get install -y \
    qemu-kvm \
    libvirt-daemon-system \
    libvirt-clients \
    bridge-utils \
    virt-manager \
    ovmf

# Install LXD
log "Installing LXD..."
snap install lxd

# Initialize LXD
log "Initializing LXD..."
cat > /tmp/lxd-init.yaml << EOL
config:
  images.auto_update_interval: "0"
networks:
- config:
    ipv4.address: auto
    ipv6.address: auto
  description: ""
  name: lxdbr0
  type: bridge
storage_pools:
- config:
    size: 50GB
  description: ""
  name: default
  driver: zfs
profiles:
- config: {}
  description: Default LXD profile
  devices:
    eth0:
      name: eth0
      network: lxdbr0
      type: nic
    root:
      path: /
      pool: default
      type: disk
  name: default
EOL

lxd init --preseed < /tmp/lxd-init.yaml
rm /tmp/lxd-init.yaml

# Configure user permissions
log "Configuring user permissions..."
usermod -aG libvirt $SUDO_USER
usermod -aG lxd $SUDO_USER

# Enable and start services
log "Starting services..."
systemctl enable --now libvirtd
systemctl enable --now virtlogd

# Create default network bridge for KVM
log "Setting up KVM network bridge..."
cat > /etc/netplan/01-netcfg.yaml << EOL
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: no
  bridges:
    br0:
      interfaces: [eth0]
      dhcp4: yes
EOL

# Apply network configuration
netplan apply

log "Virtualization setup complete!"
echo "Remember to:"
echo "1. Log out and back in for group changes to take effect"
echo "2. Test KVM with: virsh list --all"
echo "3. Test LXD with: lxc list"
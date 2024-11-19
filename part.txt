#!/bin/bash
# Disk Partitioning and LVM Setup Script
# WARNING: This script will modify disk partitions. Use with caution!

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

log() { echo -e "${GREEN}[SETUP]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Check if running as root
[[ $EUID -ne 0 ]] && error "Please run as root"

# Get disk name from user
read -p "Enter disk name to partition (e.g., sda, nvme0n1): " DISK
DISK="/dev/${DISK}"

# Verify disk exists
[[ ! -b $DISK ]] && error "Disk $DISK not found"

# Confirm destruction of data
read -p "WARNING: This will destroy all data on $DISK. Continue? (y/N): " confirm
[[ $confirm != "y" ]] && error "Operation cancelled"

# Create partition table and partitions
log "Creating partition table..."
parted $DISK mklabel gpt

# Create partitions
parted $DISK mkpart primary fat32 1MiB 512MiB  # EFI partition
parted $DISK set 1 esp on
parted $DISK mkpart primary ext4 512MiB 1536MiB  # /boot partition
parted $DISK mkpart primary 1536MiB 100%  # LVM partition

# Setup LVM
log "Setting up LVM..."
pvcreate "${DISK}3"
vgcreate vg0 "${DISK}3"

# Create logical volumes
lvcreate -L 32G vg0 -n swap
lvcreate -L 100G vg0 -n root
lvcreate -l 100%FREE vg0 -n home

# Format partitions
log "Formatting partitions..."
mkfs.fat -F32 "${DISK}1"
mkfs.ext4 "${DISK}2"
mkfs.ext4 /dev/vg0/root
mkfs.ext4 /dev/vg0/home
mkswap /dev/vg0/swap

# Mount partitions (if installing)
log "Mount points created. Use these commands during installation:"
echo "mount /dev/vg0/root /mnt"
echo "mkdir /mnt/{home,boot,boot/efi}"
echo "mount /dev/vg0/home /mnt/home"
echo "mount ${DISK}2 /mnt/boot"
echo "mount ${DISK}1 /mnt/boot/efi"
echo "swapon /dev/vg0/swap"
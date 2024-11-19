#!/bin/bash

# System Setup and Configuration Script
# Run this script after fresh Linux installation

# Exit on any error
set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[SETUP]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then 
    error "Please run as root"
fi

# Create necessary directories
log "Creating directory structure..."
mkdir -p ~/.ssh
mkdir -p ~/projects
mkdir -p ~/scripts
mkdir -p ~/.config

# Generate SSH key if it doesn't exist
if [ ! -f ~/.ssh/id_ed25519 ]; then
    log "Generating SSH key..."
    ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""
    log "SSH key generated. Don't forget to add it to your Git services!"
    cat ~/.ssh/id_ed25519.pub
fi

# Update system
log "Updating system packages..."
apt-get update && apt-get upgrade -y

# Install essential packages
log "Installing essential packages..."
PACKAGES=(
    git
    curl
    wget
    vim
    tmux
    htop
    unzip
    build-essential
    python3
    python3-pip
    docker.io
)

apt-get install -y "${PACKAGES[@]}"

# Setup Docker
log "Configuring Docker..."
systemctl start docker
systemctl enable docker
usermod -aG docker $SUDO_USER

# Configure Git
log "Configuring Git..."
read -p "Enter your Git email: " git_email
read -p "Enter your Git name: " git_name
git config --global user.email "$git_email"
git config --global user.name "$git_name"

# Setup basic vim configuration
log "Configuring Vim..."
cat > ~/.vimrc << EOL
syntax on
set number
set autoindent
set expandtab
set tabstop=4
set shiftwidth=4
EOL

# Setup bash aliases
log "Setting up bash aliases..."
cat >> ~/.bashrc << EOL

# Custom aliases
alias ll='ls -la'
alias update='sudo apt-get update && sudo apt-get upgrade -y'
alias projects='cd ~/projects'
alias scripts='cd ~/scripts'
EOL

# Setup automatic updates
log "Setting up automatic updates..."
cat > /etc/apt/apt.conf.d/20auto-upgrades << EOL
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOL

# Create a basic backup script
log "Creating backup script..."
cat > ~/scripts/backup.sh << EOL
#!/bin/bash
backup_dir="\$HOME/backups/\$(date +%Y%m%d)"
mkdir -p "\$backup_dir"
cp -r \$HOME/projects "\$backup_dir"
cp -r \$HOME/.ssh "\$backup_dir"
cp \$HOME/.bashrc "\$backup_dir"
cp \$HOME/.vimrc "\$backup_dir"
EOL
chmod +x ~/scripts/backup.sh

# Final setup
log "Running final configurations..."
source ~/.bashrc

log "Setup complete! System is ready for use."
echo "Remember to:"
echo "1. Add your SSH key to Git services"
echo "2. Customize .vimrc and .bashrc as needed"
echo "3. Set up any project-specific configurations"
echo "4. Run 'source ~/.bashrc' to apply changes in current session"

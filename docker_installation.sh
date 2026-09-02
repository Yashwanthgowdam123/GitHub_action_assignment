#!/bin/bash

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

echo "========================================="
echo " Docker Installation Script"
echo "========================================="

#########################################
# Check Docker
#########################################

if command -v docker >/dev/null 2>&1; then
    echo "Docker is already installed."

    docker --version
    docker compose version

    sudo systemctl enable docker
    sudo systemctl start docker

    echo "Skipping installation."
    exit 0
fi

#########################################
# Remove Old Docker Packages
#########################################

echo
echo "[1/9] Removing old Docker packages..."

sudo apt-get remove -y \
    docker.io \
    docker-doc \
    docker-compose \
    docker-compose-v2 \
    docker-buildx \
    podman-docker \
    containerd \
    runc || true

#########################################
# Clean Previous Repository
#########################################

echo
echo "[2/9] Cleaning old Docker repositories..."

sudo rm -f /etc/apt/sources.list.d/docker.list
sudo rm -f /etc/apt/sources.list.d/docker.sources

sudo rm -f /etc/apt/keyrings/docker.asc
sudo rm -f /etc/apt/keyrings/docker.gpg

#########################################
# Update Packages
#########################################

echo
echo "[3/9] Updating package index..."

sudo apt-get update -y

#########################################
# Install Prerequisites
#########################################

echo
echo "[4/9] Installing prerequisites..."

sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg

#########################################
# Create Keyring Directory
#########################################

echo
echo "[5/9] Creating Docker keyring..."

sudo install -m 0755 -d /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
| sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

sudo chmod a+r /etc/apt/keyrings/docker.gpg

#########################################
# Add Docker Repository
#########################################

echo
echo "[6/9] Adding Docker repository..."

echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
| sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

#########################################
# Update Repository
#########################################

echo
echo "[7/9] Updating package index..."

sudo apt-get update -y

#########################################
# Install Docker
#########################################

echo
echo "[8/9] Installing Docker Engine..."

sudo apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

#########################################
# Start Docker
#########################################

echo
echo "[9/9] Starting Docker..."

sudo systemctl enable docker
sudo systemctl restart docker

sleep 5

#########################################
# Verification
#########################################

echo
echo "========================================="
echo " Docker Installed Successfully"
echo "========================================="

echo

docker --version
docker compose version

echo

sudo systemctl --no-pager --full status docker

echo
echo "========================================="
echo " Installation Completed Successfully"
echo "========================================="

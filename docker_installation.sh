#!/bin/bash

set -e

export DEBIAN_FRONTEND=noninteractive

echo "========================================="
echo " Docker Installation Started"
echo "========================================="

echo "[1/8] Removing old Docker packages..."
sudo apt-get remove -y \
    docker.io \
    docker-doc \
    docker-compose \
    docker-compose-v2 \
    docker-buildx \
    podman-docker \
    containerd \
    runc || true

echo "[2/8] Updating package index..."
sudo apt-get update -y

echo "[3/8] Installing required packages..."
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

echo "[4/8] Creating keyrings directory..."
sudo install -m 0755 -d /etc/apt/keyrings

echo "[5/8] Downloading Docker GPG key..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
| sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo "[6/8] Adding Docker Repository..."

echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
| sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

echo "[7/8] Updating package index..."
sudo apt-get update -y

echo "[8/8] Installing Docker Engine..."
sudo apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

echo "Enabling Docker Service..."
sudo systemctl enable docker

echo "Starting Docker Service..."
sudo systemctl restart docker

echo "Waiting for Docker..."
sleep 5

echo "Verifying Installation..."

docker --version
docker compose version

sudo systemctl is-active --quiet docker

echo "========================================="
echo " Docker Installed Successfully"
echo "========================================="

#!/bin/bash

echo "========================================="
echo " Docker Installation Started"
echo "========================================="

echo "[1/8] Removing old Docker packages..."
sudo apt remove $(dpkg --get-selections docker.io docker-compose docker-compose-v2 docker-doc docker-buildx podman-docker containerd runc | cut -f1)

echo "[2/8] Updating package index..."
sudo apt update

echo "[3/8] Installing required packages..."
sudo apt install ca-certificates curl

echo "[4/8] Creating keyrings directory..."
sudo install -m 0755 -d /etc/apt/keyrings

echo "[5/8] Downloading Docker GPG key..."
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc

echo "[6/8] Setting permissions on Docker GPG key..."
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo "[7/8] Adding Docker APT repository..."
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

echo "[8/8] Updating package index and installing Docker..."
sudo apt update

sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "Checking Docker service status..."
sudo systemctl status docker

echo "Starting Docker service..."
sudo systemctl start docker

echo "========================================="
echo " Docker Installation Completed"
echo "========================================="

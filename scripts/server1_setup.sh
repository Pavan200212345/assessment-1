#!/bin/bash

set -e

echo "======================================"
echo " Server 1 Setup"
echo " Employee Management System"
echo "======================================"

echo "[1/5] Updating Ubuntu..."
sudo apt update
sudo apt upgrade -y

echo "[2/5] Installing required packages..."
sudo apt install -y ca-certificates curl git

echo "[3/5] Installing Docker..."

if command -v docker >/dev/null 2>&1; then
    echo "Docker is already installed."
else
    sudo install -m 0755 -d /etc/apt/keyrings

    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
        -o /etc/apt/keyrings/docker.asc

    sudo chmod a+r /etc/apt/keyrings/docker.asc

    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt update

    sudo apt install -y \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin
fi

echo "[4/5] Enabling Docker..."

sudo systemctl enable docker
sudo systemctl start docker

echo "[5/5] Creating application directory..."

sudo mkdir -p /opt/employee-management
sudo mkdir -p /opt/employee-management/nginx

sudo chown -R "$USER":"$USER" /opt/employee-management

echo ""
echo "======================================"
echo " Server 1 setup completed successfully"
echo "======================================"

echo ""
echo "Docker version:"
docker --version

echo ""
echo "Docker Compose version:"
docker compose version

echo ""
echo "Application directory:"
echo "/opt/employee-management"
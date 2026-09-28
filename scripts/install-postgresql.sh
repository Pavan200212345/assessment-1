#!/bin/bash

set -e

echo "======================================"
echo " PostgreSQL Server Setup"
echo "======================================"

echo "[1/5] Updating packages..."
sudo apt update

echo "[2/5] Installing PostgreSQL..."
sudo apt install -y postgresql postgresql-contrib

echo "[3/5] Installing AWS CLI..."

if command -v aws >/dev/null 2>&1; then
    echo "AWS CLI already installed."
else
    curl -fsSL https://awscli.amazonaws.com/v2/install.sh | sudo bash -s -- --system
fi

echo "[4/5] Starting PostgreSQL..."
sudo systemctl enable postgresql
sudo systemctl start postgresql

echo "[5/5] Verifying installation..."

if ! sudo systemctl is-active --quiet postgresql; then
    echo "ERROR: PostgreSQL is not running."
    exit 1
fi

echo ""
echo "PostgreSQL:"
psql --version

echo ""
echo "AWS CLI:"
aws --version

echo ""
echo "PostgreSQL setup completed successfully."

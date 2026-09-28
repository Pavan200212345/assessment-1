#!/bin/bash

set -e

echo "======================================"
echo " PostgreSQL Installation"
echo "======================================"

echo "[1/5] Updating packages..."
sudo apt update

echo "[2/5] Installing PostgreSQL..."
sudo apt install -y postgresql postgresql-contrib

echo "[3/5] Starting PostgreSQL..."
sudo systemctl start postgresql

echo "[4/5] Enabling PostgreSQL..."
sudo systemctl enable postgresql

echo "[5/5] Verifying installation..."

if sudo systemctl is-active --quiet postgresql; then
    echo "PostgreSQL is running."
else
    echo "ERROR: PostgreSQL is not running."
    exit 1
fi

echo ""
echo "PostgreSQL version:"
psql --version

echo ""
echo "PostgreSQL installation completed successfully."
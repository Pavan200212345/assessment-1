#!/bin/bash

set -e

echo "======================================"
echo " PostgreSQL Network Configuration"
echo " Employee Management System"
echo "======================================"

if [ -z "$1" ]; then
    echo "ERROR: Server 1 private IP is required."
    echo ""
    echo "Usage:"
    echo "./configure_postgresql.sh <SERVER1_PRIVATE_IP>"
    echo ""
    echo "Example:"
    echo "./configure_postgresql.sh 10.10.0.5"
    exit 1
fi

SERVER1_PRIVATE_IP="$1"

DB_NAME="employee_management"
DB_USER="employee_app"

echo "Server 1 private IP:"
echo "$SERVER1_PRIVATE_IP"

echo ""
echo "[1/5] Detecting PostgreSQL configuration files..."

PG_CONF=$(sudo -u postgres psql -tAc "SHOW config_file;" | xargs)
PG_HBA=$(sudo -u postgres psql -tAc "SHOW hba_file;" | xargs)

echo "PostgreSQL configuration:"
echo "$PG_CONF"

echo "PostgreSQL authentication configuration:"
echo "$PG_HBA"

echo ""
echo "[2/5] Configuring PostgreSQL network access..."

sudo sed -i \
    "s/^#listen_addresses = 'localhost'/listen_addresses = '*'/" \
    "$PG_CONF"

sudo sed -i \
    "s/^listen_addresses = 'localhost'/listen_addresses = '*'/" \
    "$PG_CONF"

echo ""
echo "[3/5] Configuring client authentication..."

sudo cp "$PG_HBA" "${PG_HBA}.backup"

sudo sed -i \
    "/# Employee Management Application Server/d" \
    "$PG_HBA"

sudo sed -i \
    "\|host    $DB_NAME    $DB_USER    $SERVER1_PRIVATE_IP/32    scram-sha-256|d" \
    "$PG_HBA"

sudo bash -c "cat >> '$PG_HBA' <<EOF

# Employee Management Application Server
host    $DB_NAME    $DB_USER    $SERVER1_PRIVATE_IP/32    scram-sha-256
EOF"

echo ""
echo "[4/5] Restarting PostgreSQL..."

sudo systemctl restart postgresql

echo ""
echo "[5/5] Verifying PostgreSQL..."

sudo systemctl is-active --quiet postgresql

echo ""
echo "======================================"
echo " PostgreSQL configuration completed"
echo "======================================"

echo ""
echo "Database:"
echo "$DB_NAME"

echo "Application user:"
echo "$DB_USER"

echo "Allowed Server 1 private IP:"
echo "$SERVER1_PRIVATE_IP"

echo ""
echo "PostgreSQL is now configured to accept"
echo "connections from Server 1."
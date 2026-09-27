#!/bin/bash

set -e

echo "======================================"
echo " PostgreSQL Server Setup"
echo " Employee Management System"
echo "======================================"

DB_NAME="employee_management"
DB_USER="employee_app"

echo "[1/6] Updating Ubuntu..."

sudo apt update

echo "[2/6] Installing PostgreSQL..."

sudo apt install -y postgresql postgresql-contrib

echo "[3/6] Enabling PostgreSQL..."

sudo systemctl enable postgresql
sudo systemctl start postgresql

echo "[4/6] Creating application user..."

sudo -u postgres psql <<EOF
DO \$\$
BEGIN
    IF NOT EXISTS (
        SELECT FROM pg_catalog.pg_roles
        WHERE rolname = '$DB_USER'
    ) THEN
        CREATE ROLE $DB_USER LOGIN;
    END IF;
END
\$\$;
EOF

echo "[5/6] Creating database..."

sudo -u postgres psql <<EOF
SELECT 'CREATE DATABASE $DB_NAME OWNER $DB_USER'
WHERE NOT EXISTS (
    SELECT FROM pg_database
    WHERE datname = '$DB_NAME'
)\gexec
EOF

echo "[6/6] Checking PostgreSQL..."

sudo systemctl is-active --quiet postgresql

echo ""
echo "======================================"
echo " PostgreSQL setup completed"
echo "======================================"

echo ""
echo "Database:"
echo "$DB_NAME"

echo "Application user:"
echo "$DB_USER"

echo ""
echo "IMPORTANT:"
echo "The employee_app password must be configured"
echo "before Server 1 connects to PostgreSQL."
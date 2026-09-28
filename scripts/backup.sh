#!/bin/bash

set -e

BACKUP_DIR="/var/backups/postgresql"
DATABASE_NAME="employee_management"

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_FILE="${BACKUP_DIR}/backup-${TIMESTAMP}.sql"

echo "======================================"
echo " PostgreSQL Backup"
echo "======================================"

echo "[1/4] Creating backup directory..."

sudo mkdir -p "$BACKUP_DIR"

echo "[2/4] Running pg_dump..."

sudo -u postgres pg_dump "$DATABASE_NAME" > "$BACKUP_FILE"

echo "[3/4] Verifying backup..."

if [ ! -s "$BACKUP_FILE" ]; then
    echo "ERROR: Backup file was not created correctly."
    exit 1
fi

echo "[4/4] Backup completed successfully."

echo ""
echo "Backup file:"
echo "$BACKUP_FILE"

echo ""
echo "Backup size:"
ls -lh "$BACKUP_FILE"
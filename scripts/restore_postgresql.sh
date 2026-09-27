#!/bin/bash

set -e

echo "======================================"
echo " PostgreSQL Restore"
echo " Employee Management System"
echo "======================================"

DB_NAME="employee_management"

RESTORE_DIR="/var/backups/employee-management/restore"

if [ -z "$1" ]; then
    echo "ERROR: Backup filename is required."
    echo ""
    echo "Usage:"
    echo "./restore_postgresql.sh <backup-file.sql.gz>"
    exit 1
fi

BACKUP_FILE="$1"
DOWNLOADED_FILE="$RESTORE_DIR/$BACKUP_FILE"

echo "[1/6] Checking required environment variables..."

if [ -z "$SPACES_BUCKET" ]; then
    echo "ERROR: SPACES_BUCKET is not set."
    exit 1
fi

if [ -z "$SPACES_ENDPOINT" ]; then
    echo "ERROR: SPACES_ENDPOINT is not set."
    exit 1
fi

if [ -z "$AWS_ACCESS_KEY_ID" ]; then
    echo "ERROR: AWS_ACCESS_KEY_ID is not set."
    exit 1
fi

if [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    echo "ERROR: AWS_SECRET_ACCESS_KEY is not set."
    exit 1
fi

echo "[2/6] Checking AWS CLI..."

if ! command -v aws >/dev/null 2>&1; then
    echo "ERROR: AWS CLI is not installed."
    exit 1
fi

echo "[3/6] Creating restore directory..."

sudo mkdir -p "$RESTORE_DIR"
sudo chown "$USER":"$USER" "$RESTORE_DIR"

echo "[4/6] Downloading backup from DigitalOcean Spaces..."

aws s3 cp \
    "s3://$SPACES_BUCKET/postgresql-backups/$BACKUP_FILE" \
    "$DOWNLOADED_FILE" \
    --endpoint-url "$SPACES_ENDPOINT"

if [ ! -f "$DOWNLOADED_FILE" ]; then
    echo "ERROR: Backup download failed."
    exit 1
fi

echo "[5/6] Decompressing backup..."

gunzip -f "$DOWNLOADED_FILE"

SQL_FILE="${DOWNLOADED_FILE%.gz}"

echo "[6/6] Restoring database..."

sudo -u postgres psql \
    -v ON_ERROR_STOP=1 \
    -d "$DB_NAME" \
    -f "$SQL_FILE"

echo ""
echo "Cleaning temporary SQL file..."

rm -f "$SQL_FILE"

echo ""
echo "======================================"
echo " Database restore completed"
echo "======================================"

echo ""
echo "Database:"
echo "$DB_NAME"
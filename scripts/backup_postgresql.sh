#!/bin/bash

set -e

echo "======================================"
echo " PostgreSQL Backup"
echo " Employee Management System"
echo "======================================"

DB_NAME="employee_management"
DB_USER="employee_app"

BACKUP_DIR="/var/backups/employee-management"

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

BACKUP_FILE="$BACKUP_DIR/${DB_NAME}_${TIMESTAMP}.sql"

echo "[1/6] Creating backup directory..."

sudo mkdir -p "$BACKUP_DIR"
sudo chown "$USER":"$USER" "$BACKUP_DIR"

echo "[2/6] Checking PostgreSQL connection..."

PGPASSWORD="$DB_PASSWORD" psql \
    -h "${DB_HOST:-localhost}" \
    -p "${DB_PORT:-5432}" \
    -U "$DB_USER" \
    -d "$DB_NAME" \
    -c "SELECT 1;" > /dev/null

echo "[3/6] Creating PostgreSQL dump..."

PGPASSWORD="$DB_PASSWORD" pg_dump \
    -h "${DB_HOST:-localhost}" \
    -p "${DB_PORT:-5432}" \
    -U "$DB_USER" \
    -d "$DB_NAME" \
    -F p \
    -f "$BACKUP_FILE"

echo "[4/6] Compressing backup..."

gzip "$BACKUP_FILE"

BACKUP_FILE="${BACKUP_FILE}.gz"

echo "Backup created:"
echo "$BACKUP_FILE"

echo "[5/6] Checking AWS CLI..."

if ! command -v aws >/dev/null 2>&1; then
    echo "ERROR: AWS CLI is not installed."
    exit 1
fi

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

echo "[6/6] Uploading backup to DigitalOcean Spaces..."

aws s3 cp \
    "$BACKUP_FILE" \
    "s3://$SPACES_BUCKET/postgresql-backups/" \
    --endpoint-url "$SPACES_ENDPOINT"

echo ""
echo "======================================"
echo " Backup completed successfully"
echo "======================================"

echo ""
echo "Local backup:"
echo "$BACKUP_FILE"

echo ""
echo "Remote location:"
echo "s3://$SPACES_BUCKET/postgresql-backups/"
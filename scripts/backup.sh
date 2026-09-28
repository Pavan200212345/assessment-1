#!/bin/bash

set -e

# ======================================
# PostgreSQL Backup Configuration
# ======================================

DATABASE_NAME="devops_test"

BACKUP_DIR="/var/backups/postgresql"

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

BACKUP_FILE="${BACKUP_DIR}/backup-${TIMESTAMP}.sql"

# Set these on Server 2 before running the script.
S3_BUCKET="${S3_BUCKET:?S3_BUCKET is not set}"
S3_PREFIX="${S3_PREFIX:-postgres-backups}"
AWS_REGION="${AWS_REGION:?AWS_REGION is not set}"

S3_OBJECT="s3://${S3_BUCKET}/${S3_PREFIX}/$(basename "$BACKUP_FILE")"


echo "======================================"
echo " PostgreSQL Backup"
echo "======================================"

# --------------------------------------
# Check required commands
# --------------------------------------

echo "[1/7] Checking dependencies..."

command -v pg_dump >/dev/null 2>&1 || {
    echo "ERROR: pg_dump is not installed."
    exit 1
}

command -v aws >/dev/null 2>&1 || {
    echo "ERROR: AWS CLI is not installed."
    exit 1
}


# --------------------------------------
# Create backup directory
# --------------------------------------

echo "[2/7] Preparing backup directory..."

sudo mkdir -p "$BACKUP_DIR"

sudo chmod 700 "$BACKUP_DIR"


# --------------------------------------
# Create PostgreSQL backup
# --------------------------------------

echo "[3/7] Running pg_dump..."

sudo -u postgres pg_dump "$DATABASE_NAME" > "$BACKUP_FILE"


# --------------------------------------
# Verify backup file
# --------------------------------------

echo "[4/7] Verifying backup file..."

if [ ! -s "$BACKUP_FILE" ]; then
    echo "ERROR: Backup file is empty or was not created."
    exit 1
fi

echo "Backup created:"
echo "$BACKUP_FILE"

ls -lh "$BACKUP_FILE"


# --------------------------------------
# Upload to S3
# --------------------------------------

echo "[5/7] Uploading backup to S3..."

aws s3 cp \
    "$BACKUP_FILE" \
    "$S3_OBJECT" \
    --region "$AWS_REGION"


# --------------------------------------
# Verify S3 upload
# --------------------------------------

echo "[6/7] Verifying S3 upload..."

aws s3 ls \
    "$S3_OBJECT" \
    --region "$AWS_REGION"


# --------------------------------------
# Complete
# --------------------------------------

echo "[7/7] Backup completed successfully."

echo ""
echo "Local backup:"
echo "$BACKUP_FILE"

echo ""
echo "S3 object:"
echo "$S3_OBJECT"

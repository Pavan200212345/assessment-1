#!/bin/bash

set -e

echo "======================================"
echo " PostgreSQL Backup Cron Setup"
echo " Employee Management System"
echo "======================================"

BACKUP_SCRIPT="/opt/employee-management/scripts/backup_postgresql.sh"
ENV_FILE="/opt/employee-management/.backup-env"
CRON_FILE="/etc/cron.d/employee-postgresql-backup"

echo "[1/5] Checking backup script..."

if [ ! -f "$BACKUP_SCRIPT" ]; then
    echo "ERROR: Backup script not found:"
    echo "$BACKUP_SCRIPT"
    exit 1
fi

echo "[2/5] Making backup script executable..."

sudo chmod +x "$BACKUP_SCRIPT"

echo "[3/5] Checking backup environment file..."

if [ ! -f "$ENV_FILE" ]; then
    echo "ERROR: Backup environment file not found:"
    echo "$ENV_FILE"
    echo ""
    echo "Create this file before enabling the cron job."
    exit 1
fi

sudo chmod 600 "$ENV_FILE"

echo "[4/5] Creating daily cron job..."

sudo tee "$CRON_FILE" > /dev/null <<EOF
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

0 2 * * * root . "$ENV_FILE" && "$BACKUP_SCRIPT" >> /var/log/employee-backup.log 2>&1
EOF

sudo chmod 644 "$CRON_FILE"

echo "[5/5] Verifying cron configuration..."

sudo cat "$CRON_FILE"

echo ""
echo "======================================"
echo " Cron setup completed successfully"
echo "======================================"

echo ""
echo "Backup schedule:"
echo "Every day at 02:00"

echo ""
echo "Backup log:"
echo "/var/log/employee-backup.log"
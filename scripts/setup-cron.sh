#!/bin/bash

set -e

BACKUP_SCRIPT="/opt/assessment-1/scripts/backup.sh"
LOG_FILE="/var/log/postgresql-backup.log"

SCHEDULE="0 */3 * * *"

# Set these before running the script
S3_BUCKET="${S3_BUCKET:?S3_BUCKET is not set}"
S3_PREFIX="${S3_PREFIX:-postgres-backups}"
AWS_REGION="${AWS_REGION:-ap-south-1}"

echo "======================================"
echo " PostgreSQL Cron Setup"
echo "======================================"

if [ ! -f "$BACKUP_SCRIPT" ]; then
    echo "ERROR: Backup script not found:"
    echo "$BACKUP_SCRIPT"
    exit 1
fi

chmod +x "$BACKUP_SCRIPT"

CRON_JOB="$SCHEDULE S3_BUCKET='$S3_BUCKET' S3_PREFIX='$S3_PREFIX' AWS_REGION='$AWS_REGION' $BACKUP_SCRIPT >> $LOG_FILE 2>&1"

# Remove an existing identical cron entry if present
sudo crontab -l 2>/dev/null | grep -vF "$BACKUP_SCRIPT" | sudo crontab - || true

# Add the new cron job
(
    sudo crontab -l 2>/dev/null
    echo "$CRON_JOB"
) | sudo crontab -

echo ""
echo "Cron configured successfully."
echo ""
echo "Schedule:"
echo "Every 3 hours"
echo ""
echo "Cron entry:"
sudo crontab -l

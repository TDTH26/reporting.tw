#!/usr/bin/env bash
# Nightly backup: MySQL dump of the reporting database (kept 14 days). Evidence files live in
# /sites/reporting.tw/data: include that directory in your VM snapshot / file backup as well.
# Install (as root): cp backup.sh /usr/local/bin/reporting-backup && chmod 755 /usr/local/bin/reporting-backup
#                    echo "15 3 * * * root /usr/local/bin/reporting-backup" > /etc/cron.d/reporting-backup
set -euo pipefail
DIR=/var/backups/reporting
install -d -m 700 "$DIR"
mysqldump --single-transaction --routines --triggers reporting | gzip > "$DIR/reporting-$(date +%Y%m%d-%H%M).sql.gz"
find "$DIR" -name 'reporting-*.sql.gz' -mtime +14 -delete

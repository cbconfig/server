#!/bin/bash

# =====================================================================
# 🕒 routine.sh: VPS Automated Maintenance, Watchdogs & Cron Configuration
# =====================================================================
# Usage:
#   chmod +x clean/routine.sh
#   sudo ./clean/routine.sh
#
# Installs modular maintenance scripts into /usr/local/bin:
#   - disk-cleanup.sh: Daily journal, logrotate & apt cleanup
#   - ram-cleanup.sh:  30-min RAM & Swap pressure watchdog
#   - ufw-cleanup.sh:  Weekly firewall port audit
# And configures the crontab maintenance schedule.
# =====================================================================

set -euo pipefail

echo "🕒 Starting Automated Routine Maintenance Setup..."

# Root check
if [ "$EUID" -ne 0 ]; then
    echo "❌ Please run directly as root (e.g., sudo ./clean/routine.sh)."
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

# Ensure cron is installed and active
if ! dpkg -l | grep -q "^ii  cron "; then
    echo "🕒 Installing cron for scheduled cleanups..."
    DEBIAN_FRONTEND=noninteractive apt-get update -y >/dev/null 2>&1 || true
    DEBIAN_FRONTEND=noninteractive apt-get install -y -o Dpkg::Options::="--force-confold" cron >/dev/null 2>&1 || true
fi
systemctl enable cron 2>/dev/null || true
systemctl start cron 2>/dev/null || true

# 1. Install utilities from clean/ directory to /usr/local/bin
echo "💾 Installing maintenance utilities to /usr/local/bin..."

install -m 0755 "$SCRIPT_DIR/disk-cleanup.sh" /usr/local/bin/disk-cleanup.sh
install -m 0755 "$SCRIPT_DIR/ram-cleanup.sh" /usr/local/bin/ram-cleanup.sh
install -m 0755 "$SCRIPT_DIR/ufw-cleanup.sh" /usr/local/bin/ufw-cleanup.sh

echo "✅ Utilities installed: disk-cleanup.sh, ram-cleanup.sh, ufw-cleanup.sh"

# 2. Configure Crontab Maintenance Schedule
echo "🕒 Scheduling automated maintenance tasks in crontab..."
(
  crontab -l 2>/dev/null | grep -v -E "docker system prune|docker image prune|ufw-cleanup.sh|ram-cleanup.sh|disk-cleanup.sh" || true
  # Check memory & swap pressure every 30 minutes
  echo "*/30 * * * * /usr/local/bin/ram-cleanup.sh >/dev/null 2>&1"
  # Daily automated disk and log cleanup at 04:00 AM
  echo "0 4 * * * /usr/local/bin/disk-cleanup.sh >/dev/null 2>&1"
  # Daily low-impact memory and disk sync at 04:30 AM
  echo "30 4 * * * /usr/local/bin/ram-cleanup.sh && sync >/dev/null 2>&1"
  # Weekly Sunday deep sweep: Docker prune at 03:00 AM, Firewall port audit at 04:30 AM
  echo "0 3 * * 0 docker system prune -af >/dev/null 2>&1"
  echo "30 4 * * 0 /usr/local/bin/ufw-cleanup.sh >/dev/null 2>&1"
) | crontab -
echo "✅ Maintenance cron schedule configured successfully."

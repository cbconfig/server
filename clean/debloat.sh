#!/bin/bash

# =====================================================================
# 🧹 debloat.sh: One-Time Linux OS Debloater & Memory/Disk Reclamation
# =====================================================================
# Usage:
#   chmod +x clean/debloat.sh
#   sudo ./clean/debloat.sh
#
# Strips standard Debian & Ubuntu cloud/VPS images down to a lean, dedicated Docker host:
#   1. Purges unnecessary daemons (rpcbind, avahi, cups, exim4, modemmanager, multipath-tools, snapd).
#   2. Caps systemd-journald logs to 50MB max with 7-day retention.
#   3. Configures global logrotate limits and auto-cleaning /tmp tmpfiles.
#   4. Evicts stale package caches, old kernels, and orphaned libraries.
#   5. Empties stale /tmp and rotated log files.
#   6. Flushes inactive kernel filesystem buffers.
# =====================================================================

set -euo pipefail

echo "🧹 Starting OS Debloat & System Cleanup..."

# Root check
if [ "$EUID" -ne 0 ]; then
    echo "❌ Please run directly as root (e.g., sudo ./clean/debloat.sh)."
    exit 1
fi

# Ensure running on Debian or Ubuntu
OS_ID=""
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_ID=$(echo "$ID" | tr '[:upper:]' '[:lower:]')
fi

if [ "$OS_ID" != "debian" ] && [ "$OS_ID" != "ubuntu" ]; then
    if [ ! -f /etc/debian_version ]; then
        echo "❌ ERROR: This cleanup script supports Debian and Ubuntu Linux."
        exit 1
    fi
    OS_ID="debian"
fi

echo "🐧 Detected Linux distribution: $OS_ID"

# 1. Purge Bloated & Non-Essential Background Services
echo "🗑️ Purging non-essential background daemons..."

UNNECESSARY_SERVICES=(
    cups
    cups-daemon
    cups-browsed
    avahi-daemon
    rpcbind
    exim4
    exim4-base
    exim4-config
    modemmanager
    multipath-tools
    bluez
    snapd
)

for pkg in "${UNNECESSARY_SERVICES[@]}"; do
    if dpkg -l | grep -q "^ii  $pkg "; then
        echo "   - Purging $pkg..."
        systemctl stop "$pkg" 2>/dev/null || true
        systemctl disable "$pkg" 2>/dev/null || true
        DEBIAN_FRONTEND=noninteractive apt-get purge -y "$pkg" >/dev/null 2>&1 || true
    fi
done

# Clean up snap directories if snap was removed
if [ ! -d /snap ]; then
    rm -rf /snap /var/snap /var/lib/snapd 2>/dev/null || true
fi

# 2. Cap systemd-journald Log Storage to 50MB Max & 7-Day Retention
echo "📜 Capping system journal logs to 50MB max with 7-day retention..."
mkdir -p /etc/systemd/journald.conf.d
cat <<'EOF' > /etc/systemd/journald.conf.d/00-journal-size.conf
[Journal]
SystemMaxUse=50M
RuntimeMaxUse=25M
SystemMaxFileSize=10M
MaxRetentionSec=7day
EOF
systemctl restart systemd-journald 2>/dev/null || true
journalctl --vacuum-time=7d --vacuum-size=50M >/dev/null 2>&1 || true
echo "✅ Journal logs trimmed."

# 3. Configure Global Log Retention (daily rotate, max 7 days)
echo "📜 Hardening logrotate configuration for /var/log..."
cat <<'EOF' > /etc/logrotate.d/00-global-retention
/var/log/syslog
/var/log/mail.log
/var/log/mail.info
/var/log/mail.warn
/var/log/mail.err
/var/log/daemon.log
/var/log/auth.log
/var/log/user.log
/var/log/messages
/var/log/debug
/var/log/kern.log
{
    daily
    rotate 7
    maxsize 15M
    missingok
    notifempty
    compress
    delaycompress
    sharedscripts
    postrotate
        /usr/lib/rsyslog/rsyslog-rotate 2>/dev/null || true
    endscript
}
EOF
sed -i 's/^rotate .*/rotate 7/' /etc/logrotate.conf 2>/dev/null || true
sed -i 's/#compress/compress/' /etc/logrotate.conf 2>/dev/null || true

# Systemd tmpfiles: Auto-clean /tmp and /var/tmp files
echo "d /tmp 1777 root root 3d" > /etc/tmpfiles.d/tmp-cleanup.conf
echo "d /var/tmp 1777 root root 7d" >> /etc/tmpfiles.d/tmp-cleanup.conf

# 4. Clean APT Cache & Remove Orphaned Dependencies
echo "🧹 Cleaning apt cache and removing orphaned packages..."
DEBIAN_FRONTEND=noninteractive apt-get autoremove --purge -y >/dev/null 2>&1 || true
apt-get clean -y >/dev/null 2>&1 || true
rm -rf /var/lib/apt/lists/*
apt-get update -y >/dev/null 2>&1 || true

# 5. Clean Stale Temporary Files & Old Compressed Logs
echo "🧹 Cleaning stale /tmp and rotated log files..."
rm -rf /tmp/* /var/tmp/* 2>/dev/null || true
find /var/log -type f -regex '.*\.[0-9]+\.gz$' -delete 2>/dev/null || true
find /var/log -type f -regex '.*\.[0-9]+$' -delete 2>/dev/null || true

# 6. Flush Inactive Kernel Page Caches
echo "🧠 Evicting dormant kernel filesystem buffers..."
sync
echo 3 > /proc/sys/vm/drop_caches

echo ""
echo "🏁 OS debloat & cleanup complete!"
echo "--------------------------------------------------"
echo "Memory Status:"
free -h
echo "--------------------------------------------------"
echo "Root Disk Status:"
df -h /
echo "--------------------------------------------------"

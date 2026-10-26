#!/bin/bash
# =====================================================================
# 🧹 disk-cleanup.sh: VPS Disk & Log Hygiene Utility
# =====================================================================
# Automatically vacuums systemd journals, removes stale logs, cleans
# APT cache, and prunes old Docker buildkit caches.
# =====================================================================
set -euo pipefail

# 1. Vacuum systemd journal logs to max 50MB and max 7 days
if command -v journalctl &>/dev/null; then
    journalctl --vacuum-time=7d --vacuum-size=50M >/dev/null 2>&1 || true
fi

# 2. Clean APT package cache and lists archives
if command -v apt-get &>/dev/null; then
    apt-get clean -y >/dev/null 2>&1 || true
    apt-get autoclean -y >/dev/null 2>&1 || true
fi

# 3. Purge rotated logs older than 7 days and stale temp files
find /var/log -type f -regex '.*\.[0-9]+\.gz$' -mtime +7 -delete 2>/dev/null || true
find /var/log -type f -regex '.*\.[0-9]+$' -mtime +7 -delete 2>/dev/null || true
find /tmp /var/tmp -type f -atime +3 -delete 2>/dev/null || true

# 4. Trigger logrotate daily run to prevent runaway unrotated files
if command -v logrotate &>/dev/null; then
    logrotate /etc/logrotate.conf >/dev/null 2>&1 || true
fi

# 5. Prune dangling Docker builder caches older than 7 days
if command -v docker &>/dev/null && docker info &>/dev/null; then
    docker builder prune -f --filter "until=168h" --keep-storage 500MB >/dev/null 2>&1 || true
fi

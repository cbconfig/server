#!/bin/bash
# =====================================================================
# 🧠 ram-cleanup.sh: VPS RAM & Swap Watchdog
# =====================================================================
# Monitors system memory and safely evicts pagecache/dentries/inodes
# or prunes BuildKit caches if memory pressure spikes dangerously.
# =====================================================================
set -euo pipefail

MEM_TOTAL=$(free | awk '/^Mem:/{print $2}')
MEM_AVAILABLE=$(free | awk '/^Mem:/{print $7}')

if [ -z "$MEM_TOTAL" ] || [ "$MEM_TOTAL" -eq 0 ] || [ -z "$MEM_AVAILABLE" ]; then
    exit 0
fi

MEM_USED=$((MEM_TOTAL - MEM_AVAILABLE))
MEM_PERCENT=$((MEM_USED * 100 / MEM_TOTAL))

# Threshold 1: Elevated memory usage (>=85%) -> Safe kernel cache flush
if [ "$MEM_PERCENT" -ge 85 ]; then
    echo "⚠️ [$(date '+%Y-%m-%d %H:%M:%S')] High memory usage detected: ${MEM_PERCENT}%. Evicting filesystem caches..."
    sync
    echo 3 > /proc/sys/vm/drop_caches
fi

# Threshold 2: Critical memory pressure (>=92%) -> Evict caches + prune Docker builder caches
if [ "$MEM_PERCENT" -ge 92 ]; then
    echo "🚨 [$(date '+%Y-%m-%d %H:%M:%S')] Critical memory pressure: ${MEM_PERCENT}%. Running emergency Docker builder prune..."
    if command -v docker &>/dev/null && docker info &>/dev/null; then
        docker builder prune -f --keep-storage 500MB >/dev/null 2>&1 || true
    fi
fi

# Threshold 3: Swap Exhaustion Watchdog (>=85% Swap Used) -> Stop kswapd CPU death spirals
SWAP_TOTAL=$(free | awk '/^Swap:/{print $2}')
SWAP_FREE=$(free | awk '/^Swap:/{print $4}')
if [ -n "$SWAP_TOTAL" ] && [ "$SWAP_TOTAL" -gt 0 ] && [ -n "$SWAP_FREE" ]; then
    SWAP_USED=$((SWAP_TOTAL - SWAP_FREE))
    SWAP_PERCENT=$((SWAP_USED * 100 / SWAP_TOTAL))
    if [ "$SWAP_PERCENT" -ge 85 ]; then
        echo "🚨 [$(date '+%Y-%m-%d %H:%M:%S')] Critical Swap usage detected: ${SWAP_PERCENT}%. Evicting memory to prevent thrashing..."
        sync
        echo 3 > /proc/sys/vm/drop_caches
        if command -v docker &>/dev/null && docker info &>/dev/null; then
            docker builder prune -f --keep-storage 200MB >/dev/null 2>&1 || true
        fi
    fi
fi

# Threshold 4: Emergency Disk Safeguard (>=90% Root Disk Used)
DISK_PERCENT=$(df / | awk 'NR==2 {print $5}' | tr -d '%')
if [ -n "$DISK_PERCENT" ] && [ "$DISK_PERCENT" -ge 90 ]; then
    echo "🚨 [$(date '+%Y-%m-%d %H:%M:%S')] Critical disk usage detected: ${DISK_PERCENT}%. Running emergency Docker system prune..."
    if command -v docker &>/dev/null && docker info &>/dev/null; then
        docker system prune -f >/dev/null 2>&1 || true
    fi
fi

# Routine: Prune dead/exited containers older than 48 hours
if command -v docker &>/dev/null && docker info &>/dev/null; then
    docker container prune --filter "until=48h" -f >/dev/null 2>&1 || true
fi

#!/bin/bash
# =====================================================================
# 🛡️ ufw-cleanup.sh: Self-Cleaning Firewall Port Audit Utility
# =====================================================================
# Automatically purges UFW rules for ports that have no active
# listening process or Docker container.
# =====================================================================
set -euo pipefail

if ! command -v ufw &>/dev/null; then
    exit 0
fi

# Default whitelist of ports that should NEVER be closed automatically
WHITELIST=("22" "80" "443" "81")
CURRENT_SSH_PORT=$(ss -tlnp 2>/dev/null | grep -E 'sshd|ssh' | awk '{print $4}' | grep -oE '[0-9]+$' | head -n1 || echo "")
[ -n "$CURRENT_SSH_PORT" ] && WHITELIST+=("$CURRENT_SSH_PORT")

UFW_PORTS=$(ufw status 2>/dev/null | grep -E 'ALLOW|LIMIT|ALLOW IN|LIMIT IN' | awk '{print $1}' | grep -oE '^[0-9]+' | sort -u || true)
ACTIVE_PORTS=$(ss -tulpn 2>/dev/null | awk '{print $5}' | grep -oE ':[0-9]+$' | cut -d: -f2 | sort -u || true)

for port in $UFW_PORTS; do
    is_whitelisted=false
    for white in "${WHITELIST[@]}"; do
        if [ "$port" = "$white" ]; then
            is_whitelisted=true
            break
        fi
    done
    [ "$is_whitelisted" = true ] && continue

    is_active=false
    for active in $ACTIVE_PORTS; do
        if [ "$port" = "$active" ]; then
            is_active=true
            break
        fi
    done

    if [ "$is_active" = false ]; then
        echo "🗑️ Port $port has no active listening service. Purging from UFW..."
        ufw delete allow "$port" >/dev/null 2>&1 || true
        ufw delete allow "$port/tcp" >/dev/null 2>&1 || true
        ufw delete allow "$port/udp" >/dev/null 2>&1 || true
        ufw delete limit "$port" >/dev/null 2>&1 || true
        ufw delete limit "$port/tcp" >/dev/null 2>&1 || true
        ufw delete limit "$port/udp" >/dev/null 2>&1 || true
    fi
done
ufw reload >/dev/null 2>&1 || true

# 🛡️ Self-Cleaning Firewall Audit Utility (`clean/ufw-cleanup.sh`)

`clean/ufw-cleanup.sh` is an automated security audit script (installed to `/usr/local/bin/ufw-cleanup.sh`) that cross-references open UFW firewall ports against active listening processes and Docker containers.

---

## ⚡ Execution

```bash
# Manual run:
sudo ./clean/ufw-cleanup.sh

# Or when installed on VPS:
sudo /usr/local/bin/ufw-cleanup.sh
```

---

## 📌 How It Works

1. **Port Whitelist**:
   - Protects critical ports that must never be closed automatically:
     - `22` (SSH fallback)
     - `80` (HTTP)
     - `443` (HTTPS)
     - `81` (Admin console)
     - Current active SSH port detected dynamically via `ss -tlnp`.

2. **Active Listener Discovery**:
   - Queries `ss -tulpn` to detect all currently bound TCP and UDP ports.

3. **Orphan Port Pruning**:
   - Inspects all open ports listed in `ufw status`.
   - If an open port is not in the whitelist and has no listening service, it automatically deletes the UFW rule and reloads the firewall (`ufw reload`).

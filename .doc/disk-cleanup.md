# 💾 Disk & Log Hygiene Utility (`clean/disk-cleanup.sh`)

`clean/disk-cleanup.sh` is a standalone script (installed to `/usr/local/bin/disk-cleanup.sh`) that bounds disk usage by cleaning journals, old logs, APT archives, and dangling build artifacts.

---

## ⚡ Execution

```bash
# Manual run:
sudo ./clean/disk-cleanup.sh

# Or when installed on VPS:
sudo /usr/local/bin/disk-cleanup.sh
```

---

## 📌 Operations

1. **Systemd Journal Logs**:
   - Runs `journalctl --vacuum-time=7d --vacuum-size=50M` to keep journal size capped at 50MB.

2. **APT Package Archives**:
   - Runs `apt-get clean` and `apt-get autoclean` to purge cached `.deb` downloads.

3. **Log & Temp Retention**:
   - Deletes rotated log files (`*.gz`, `*.[0-9]`) older than 7 days in `/var/log`.
   - Cleans files in `/tmp` and `/var/tmp` older than 3 days.
   - Triggers `logrotate /etc/logrotate.conf` to rotate any unmanaged log files.

4. **Docker Build Cache**:
   - Prunes dangling Docker BuildKit caches older than 7 days (`168h`), reserving up to 500MB of storage.

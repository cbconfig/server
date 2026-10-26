# 🧹 One-Time System Debloater (`clean/debloat.sh`)

`clean/debloat.sh` performs an immediate one-time debloat of default cloud VPS baggage and reclaims disk space and RAM.

---

## ⚡ Execution

```bash
chmod +x clean/debloat.sh
sudo ./clean/debloat.sh
```

---

## 📌 Operations Performed

1. **Purges Unnecessary Services**:
   - Removes background packages typically included in cloud images: `cups`, `avahi-daemon`, `rpcbind`, `exim4`, `modemmanager`, `multipath-tools`, `bluez`, `snapd`.
   - Stops and disables their systemd services.

2. **Caps Journald Logs**:
   - Limits `systemd-journald` storage in `/etc/systemd/journald.conf.d/00-journal-size.conf` to **50MB max** with a **7-day retention**.
   - Vacuums existing logs immediately.

3. **Hardens Logrotate**:
   - Configures `/var/log` retention to 7 daily compressed rotations.
   - Cleans old rotated `.gz` files and orphaned numerical logs.

4. **Cleans Package & Temporary Caches**:
   - Runs `apt-get autoremove --purge` and `apt-get clean`.
   - Cleans temporary files in `/tmp` and `/var/tmp`.
   - Flushes inactive kernel pagecaches (`echo 3 > /proc/sys/vm/drop_caches`).

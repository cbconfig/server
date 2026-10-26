# 🕒 Automated Maintenance & Cron Installer (`clean/routine.sh`)

`clean/routine.sh` installs background monitoring utilities into `/usr/local/bin` and schedules recurring automated tasks in `crontab`.

---

## ⚡ Execution

```bash
chmod +x clean/routine.sh
sudo ./clean/routine.sh
```

---

## 📌 Architecture & Installed Utilities

1. **Installs Maintenance Utilities**:
   - `clean/disk-cleanup.sh` ➔ `/usr/local/bin/disk-cleanup.sh`
   - `clean/ram-cleanup.sh`  ➔ `/usr/local/bin/ram-cleanup.sh`
   - `clean/ufw-cleanup.sh`  ➔ `/usr/local/bin/ufw-cleanup.sh`

2. **Crontab Scheduling**:
   - `*/30 * * * *`: Runs `ram-cleanup.sh` every 30 minutes to check memory pressure.
   - `0 4 * * *`: Runs `disk-cleanup.sh` daily at 04:00 AM.
   - `30 4 * * *`: Performs a low-impact memory and filesystem `sync` daily at 04:30 AM.
   - `0 3 * * 0`: Runs `docker system prune -af` every Sunday at 03:00 AM.
   - `30 4 * * 0`: Runs `ufw-cleanup.sh` every Sunday at 04:30 AM to audit unused firewall ports.

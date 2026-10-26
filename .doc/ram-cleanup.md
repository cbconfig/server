# 🧠 RAM & Swap Memory Watchdog (`clean/ram-cleanup.sh`)

`clean/ram-cleanup.sh` is an autonomous memory watchdog (installed to `/usr/local/bin/ram-cleanup.sh`) executed every 30 minutes via crontab to prevent out-of-memory kernel panics and swap thrashing.

---

## ⚡ Execution

```bash
# Manual run:
sudo ./clean/ram-cleanup.sh

# Or when installed on VPS:
sudo /usr/local/bin/ram-cleanup.sh
```

---

## 📌 Threshold Rules

1. **Elevated Memory Usage (≥ 85%)**:
   - Executes `sync` and flushes filesystem pagecaches, dentries, and inodes (`echo 3 > /proc/sys/vm/drop_caches`).

2. **Critical Memory Pressure (≥ 92%)**:
   - Evicts kernel cache and runs an emergency Docker builder cache prune (`docker builder prune -f --keep-storage 500MB`).

3. **Swap Thrashing Defense (Swap Used ≥ 85%)**:
   - Stops `kswapd` CPU death spirals by dropping memory cache and trimming build artifacts to free active pages.

4. **Emergency Disk Safeguard (Root Disk ≥ 90%)**:
   - Triggers `docker system prune -f` to free unused images, build cache, and dangling networks before the root disk fills up completely.

5. **Exited Containers**:
   - Automatically prunes dead/exited containers older than 48 hours.

# 🚀 Base OS Provisioning & Hardening (`setup.sh`)

`setup.sh` is the core bootstrap installer that transforms a fresh **Debian or Ubuntu** VPS into a production-ready, hardened Docker host.

---

## ⚡ Execution

```bash
# From the server repository root:
chmod +x setup.sh
sudo ./setup.sh
```

---

## 📌 Architecture & Operations

1. **Configuration Resolution**:
   - Automatically loads credentials and settings from `config/index.yml` (`username`, `ssh_public_key`, `timezone`).

2. **Dedicated Service User**:
   - Creates a dedicated non-root user account matching `username`.
   - Locks password authentication (`passwd -l`), allowing key-only authentication.
   - Configures private home directory (`chmod 700`) and grants passwordless `sudo` in `/etc/sudoers.d/$USER_NAME`.

3. **SSH Hardening & Anti-Lockout Immunity**:
   - Imports public keys into `~/.ssh/authorized_keys` (`chmod 600`) and syncs a failsafe copy to `/root/.ssh/authorized_keys`.
   - Sets `PasswordAuthentication no`, `MaxAuthTries 2`, `ClientAliveInterval 300`, and restricts logins via `AllowUsers`.
   - Installs systemd priority overrides (`OOMScoreAdjust=-1000`, `CPUSchedulingPolicy=rr`, `MemoryMin=32M`) so SSH remains accessible during high CPU/memory workloads.

4. **Docker CE & Log Limits**:
   - Automatically detects OS (`debian` or `ubuntu`) and codename (`bookworm`, `noble`, etc.).
   - Installs official Docker CE, `containerd.io`, and compose plugins.
   - Sets global log caps in `/etc/docker/daemon.json` (max 10MB, 3 files per container) and DNS resolvers (`1.1.1.1`, `8.8.8.8`).
   - Adds the service user to the `docker` group.

5. **UFW Firewall with Docker Leak Defense**:
   - Restricts ports to only authorized traffic (SSH, HTTP 80, HTTPS 443).
   - Injects `DOCKER-USER` filtering into `/etc/ufw/after.rules` to prevent Docker from bypassing the host firewall.

6. **Kernel & Memory Tuning**:
   - Dynamically calibrates Swap memory (4GB–8GB) based on physical RAM with `vm.swappiness=10`.
   - Reserves 64MB kernel memory (`vm.min_free_kbytes`) and optimizes `vm.max_map_count` for databases.

7. **Delegates Cleanup & Monitoring**:
   - Automatically executes `clean/debloat.sh` and `clean/routine.sh`.

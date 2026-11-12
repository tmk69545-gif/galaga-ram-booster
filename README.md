# Nothing Galaga RAM Booster (+8GB Virtual RAM)
**Magisk / KernelSU / APatch Root Module for Custom ROMs**

---

### Overview
This root module brings the **Stock Nothing OS RAM Booster (+8GB Virtual Memory Extension)** to any Custom ROM (AOSP, LineageOS, crDroid, Evolution X, PixelOS, etc.) on the **Nothing / CMF Phone 2 Pro (Codename: Galaga)**.

It pairs your **8GB Physical RAM** with an additional **+8GB Virtual RAM** using high-speed zRAM compression and an optional UFS flash swapfile with optimized kernel virtual memory parameters.

---

### Features
1. **+8GB Virtual RAM Expansion:**
   - **zRAM Expansion:** Resizes in-memory compressed zRAM to 8192 MB (with ultra-fast `zstd` / `lz4` compression).
   - **UFS Flash Swap:** Allocates an 8192 MB swapfile on `/data/swap/ram_booster.swap` at priority 5.
2. **Hybrid Intelligent Hierarchy:**
   - Fast zRAM takes high priority (`priority 10`).
   - Slower flash storage swap takes lower priority (`priority 5`) as overflow buffer.
   - Prevents Out-Of-Memory (OOM) app crashes and heavy background kills while preserving smooth UI responsiveness.
3. **Optimized Linux Kernel VM Tuning:**
   - `vm.swappiness = 130`
   - `vm.page-cluster = 0` (eliminates readahead lag on SSD/flash swap)
   - `vm.vfs_cache_pressure = 100`
   - Smooth dirty memory writeback (`dirty_ratio = 20`, `dirty_background_ratio = 10`).
4. **Clean Uninstaller:**
   - Safely deactivates and deletes the 8GB storage swap file when uninstalled, returning disk space automatically.
5. **CLI Status Tool:**
   - Run `su -c ramboost` in Termux or ADB shell to see real-time memory and swap stats.

---

### Installation
1. Download or copy `Galaga_RAM_Booster_8GB_v1.0.zip` to your phone.
2. Open **Magisk**, **KernelSU**, or **APatch**.
3. Tap **Modules** -> **Install from storage**.
4. Select `Galaga_RAM_Booster_8GB_v1.0.zip`.
5. Reboot your device.

---

### Configuration
You can customize the module anytime by editing `/data/adb/ram_booster.conf` as root:
```sh
# Extension size in MB (e.g., 4096 for 4GB, 8192 for 8GB)
EXTENSION_SIZE_MB=8192

# Modes:
#   hybrid  : 8GB zRAM + 8GB Storage Swap (recommended)
#   storage : 8GB UFS Flash Swap only (stock Nothing OS style)
#   zram    : 8GB Compressed In-RAM only (zero flash wear)
SWAP_MODE=hybrid

# Swappiness (0-200)
SWAPPINESS=130
```

---

### Verification
Open Termux or an ADB shell on your phone and run:
```bash
su -c ramboost
```
or inspect swap devices directly:
```bash
su -c cat /proc/swaps
```

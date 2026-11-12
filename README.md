# Nothing Galaga RAM Booster (+8GB Virtual RAM)
**Complete Stock RAM Booster Suite for CMF Phone 2 Pro (`Galaga`) on Custom ROMs**

[![KernelSU](https://img.shields.io/badge/KernelSU-Supported-brightgreen.svg)](https://github.com/tiann/KernelSU)
[![Magisk](https://img.shields.io/badge/Magisk-Supported-blue.svg)](https://github.com/topjohnwu/Magisk)
[![LSPosed / Vector](https://img.shields.io/badge/LSPosed%20%2F%20Vector-Supported-orange.svg)](https://github.com/LSPosed/LSPosed)
[![Target Platform](https://img.shields.io/badge/Device-CMF%20Phone%202%20Pro%20(Galaga)-black.svg)](https://nothing.tech)

---

## 📌 Overview

On stock Nothing OS, the system includes a proprietary **RAM Booster** feature allowing users to expand their 8GB physical RAM up to **8GB + 8GB (16GB total)**. When flashing Custom ROMs (Project Infinity X, LineageOS, crDroid, Evolution X, PixelOS, etc.), this capability is lost:
1. The kernel defaults to standard zRAM with no high-capacity storage swap overflow.


This project provides a **complete, two-part production-grade solution** replicating the full stock Nothing OS RAM Booster experience on any Custom ROM.

---

## 🏗️ Architecture: The Two Components

| Component | Type | Responsibility |
| :--- | :--- | :--- |
| **1. Galaga RAM Booster Module** | Magisk / KernelSU / APatch Root Module | Backend swap engine, zRAM resizing, UFS flash swapfile management, Linux kernel VM parameter tuning, WebUI dashboard, and `ramboost` CLI. |
| **2. Galaga 8+8 RAM Hook** | LSPosed / Vector Companion APK | Frontend UI injection into Settings (`OosAboutPreference`) and Launcher3 Recents (`MemInfoView`) to display `8 GB + 8 GB (Active)`, healthy green utilization (~28%), and `11.5 GB available \| 16 GB`. |

---

## ⚙️ How the Backend Memory Engine Works

1. **Intelligent Hybrid Hierarchy:**
   - **zRAM Tier (Priority 10):** Resizes compressed RAM to 8192 MB using `zstd` / `lz4` compression for ultra-fast, zero-wear background paging.
   - **Storage Swap Tier (Priority 5):** Allocates a dedicated UFS flash swap file at `/data/swap/ram_booster.swap` as an overflow safety buffer.
   - Active memory pages are compressed into fast zRAM first; only cold, dormant pages overflow to disk swap. This eliminates Out-Of-Memory (OOM) background kills while keeping the foreground UI at a fluid 120 Hz.

2. **Kernel Virtual Memory (VM) Sysctl Tuning:**
   - `vm.swappiness = 130`: Actively migrates inactive background pages to swap, preserving physical DRAM for immediate foreground tasks.
   - `vm.page-cluster = 0`: Disables multi-page sequential readahead, preventing latency spikes on random flash reads.
   - `vm.vfs_cache_pressure = 100`: Balances inode/dentry caching against page cache reclamation.
   - `dirty_ratio = 20` & `dirty_background_ratio = 10`: Guarantees smooth dirty writebacks without micro-stutters.

---

## 🎨 How the UI Hook Works

1. **Settings About Phone Card (`OosAboutPreference`):**
   - Intercepts `setText` to transform `8 GB (Active)` into **`8 GB + 8 GB (Active)`**.
   - Intercepts `usedRamPercentage` in `lambda$onBindItems$0` to scale memory utilization out of the full 16 GB capacity ($\approx 28\%$). This turns the progress bar **green**, matching the storage bar.
2. **Recents Memory Bar (`MemInfoView`):**
   - Intercepts `ActivityManager.getMemoryInfo` to report `totalMem = 16 GB`.
   - Intercepts the Recents formatting pipeline to combine physical free RAM ($\approx 3.3\text{ GB}$) with the 8 GB virtual pool, showing **`11.5 GB available | 16 GB`** without double-boosting.

---

## 📥 Installation Guide

### Prerequisites
- **Device:** CMF Phone 2 Pro (`Galaga`), MediaTek Dimensity 7300 Pro 5G.
- **Root Engine:** [KernelSU-Next](https://github.com/rifsxd/KernelSU-Next), KernelSU, Magisk, or APatch.
- **Hook Engine:** [Vector](https://github.com/5ec1cff/Zygisk-Vector) (`zygisk_vector`) or [LSPosed](https://github.com/LSPosed/LSPosed) (Zygisk release).

---

### Step 1: Install the Root Module (Backend)
1. Download **`Galaga-RAM-Booster-v1.0.zip`** from [GitHub Releases](https://github.com/tmk69545-gif/galaga-ram-booster/releases).
2. Open your Root Manager (**KernelSU** / **Magisk** / **APatch**).
3. Go to **Modules** $\rightarrow$ **Install from storage**.
4. Select `Galaga-RAM-Booster-v1.0.zip`.
5. Tap **Reboot**.

---

### Step 2: Install the UI Hook (Frontend)
1. Download **`Galaga_8plus8_RAM_Hook_v1.0.apk`** from [GitHub Releases](https://github.com/tmk69545-gif/galaga-ram-booster/releases).
2. Install the APK on your device (tap the file in your file manager or use `adb install -r Galaga_8plus8_RAM_Hook_v1.0.apk`).

---

### Step 3: Enable the Hook in Vector / LSPosed
1. Open **Vector Manager** or **LSPosed**.
2. Tap the **Modules** tab.
3. Tap **Galaga 8+8 RAM Hook** and toggle it **ON**.
4. Check the injection scope for the following apps:
   - ✅ **System Framework** (`android`)
   - ✅ **Settings** (`com.android.settings`)
   - ✅ **Launcher3 / Quickstep** (`com.android.launcher3`)
   - ✅ **System UI** (`com.android.systemui`)
5. Restart **Settings** and **Launcher3** (or reboot your phone):
   ```bash
   adb shell "am force-stop com.android.settings && am force-stop com.android.launcher3"
   ```

---

## 🔍 Verification

### 1. Visual Verification
- **Settings:** Open **Settings $\rightarrow$ About Phone**. The RAM section should display:
  $$\mathbf{RAM:\ 8\ GB\ +\ 8\ GB\ (Active)}$$
  with a **healthy green progress bar** at $\approx 28\%$ capacity.
- **Recents Panel:** Swipe up and hold to open Recent Apps. The bottom bar will show:
  $$\mathbf{11.5\ GB\ available\ |\ 16\ GB}$$

### 2. CLI Diagnostics
Run the built-in diagnostic tool in Termux or ADB shell:
```bash
su -c ramboost
```
Expected output:
```text
==========================================
    GALAGA RAM BOOSTER STATUS
==========================================
Physical DRAM  : 7581 MB
Total Memory   : 16181 MB (Physical + Active Swap)
Available RAM  : 3450 MB (Free physical DRAM)
Total Swap     : 16384 MB (16.0 GB)
Used Swap      : 120 MB (Paging active)

Active Swap Devices:
Filename                     Type        Size       Used   Priority
/dev/block/zram0             partition   8388604    120    10
/data/swap/ram_booster.swap  file        8388604    0      5

Kernel Virtual Memory Tuning:
vm.swappiness = 130
vm.page-cluster = 0
vm.vfs_cache_pressure = 100
vm.dirty_ratio = 20
==========================================
```

You can also check the kernel swap table directly:
```bash
su -c cat /proc/swaps
```

---

## 🛠️ Configuration

You can change the virtual extension size and swap mode anytime via two methods:

### Method A: WebUI (KernelSU / Magisk Manager)
Open KernelSU or Magisk, tap the **Action / WebUI** button next to **Galaga RAM Booster**:
- **Segmented Extension Selector:** Choose `+4G`, `+6G`, `+8G`, `+10G`, or `+12G`.
- **Backing Architecture:** Select `Hybrid (zRAM + Storage)`, `zRAM Compression Only`, or `Storage Swap Only`.
- **Swappiness Slider:** Adjust kernel swappiness from `60` to `180`.
Apps Overview**: Displays **`11.5 GB available | 16 GB`** combining physical free DRAM with the +8 GB virtual pool without double-boosting.- **Live Diagnostics:** View real-time output from `/proc/swaps` and memory allocation bars.

### Method B: Manual Configuration File
Edit `/data/adb/ram_booster.conf` as root:
```sh
# Extension size in MB (e.g., 4096 for 4GB, 8192 for 8GB, 12288 for 12GB)
EXTENSION_SIZE_MB=8192

# Mode: hybrid (recommended), zram, or storage
SWAP_MODE=hybrid

# Linux kernel swappiness (0-200)
SWAPPINESS=130

# Page cluster (0 is optimal for flash storage)
PAGE_CLUSTER=0
```
Changes apply immediately or on next reboot.

---

## 🗑️ Clean Uninstallation

1. Open your Root Manager (**KernelSU** / **Magisk**).
2. Tap **Remove** on **Galaga RAM Booster**.
3. The module's [`uninstall.sh`](file:///home/unknown/Desktop/ram%20boost%20for%20galaga/uninstall.sh) script will automatically:
   - Deactivate all swap devices (`swapoff`).
   - Delete `/data/swap/ram_booster.swap` and reclaim the 8 GB storage space.
   - Clean up `/data/adb/ram_booster.conf`.
4. Uninstall the **Galaga 8+8 RAM Hook** APK normally via Android App Info.
5. Reboot your device.

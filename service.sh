#!/system/bin/sh
# ==============================================================
# Nothing Galaga RAM Booster - Boot Service Script
# Runs at late-boot (service mode)
# ==============================================================

LOG_FILE="/data/local/tmp/ram_booster.log"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting Galaga RAM Booster Service..." > "$LOG_FILE"

# Wait for boot completion
boot_counter=0
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 2
    boot_counter=$((boot_counter + 2))
    if [ "$boot_counter" -ge 60 ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Boot completed check timed out, proceeding anyway..." >> "$LOG_FILE"
        break
    fi
done

# If we had to wait for boot, give disk I/O a few seconds to settle
if [ "$boot_counter" -gt 0 ]; then
    sleep 5
fi

# Load configuration
CONF_FILE="/data/adb/ram_booster.conf"
if [ -f "$CONF_FILE" ]; then
    . "$CONF_FILE"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Loaded config from $CONF_FILE" >> "$LOG_FILE"
else
    EXTENSION_SIZE_MB=8192
    SWAP_MODE="hybrid"
    SWAPPINESS=130
    PAGE_CLUSTER=0
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Using built-in defaults: Size=${EXTENSION_SIZE_MB}MB Mode=$SWAP_MODE" >> "$LOG_FILE"
fi

[ -z "$EXTENSION_SIZE_MB" ] && EXTENSION_SIZE_MB=8192
[ -z "$SWAP_MODE" ] && SWAP_MODE="hybrid"
[ -z "$SWAPPINESS" ] && SWAPPINESS=130
[ -z "$PAGE_CLUSTER" ] && PAGE_CLUSTER=0

SWAP_DIR="/data/swap"
SWAP_FILE="$SWAP_DIR/ram_booster.swap"

# -------------------------------------------------------------
# 1. CONFIGURE zRAM (For 'hybrid' or 'zram' modes)
# -------------------------------------------------------------
if [ "$SWAP_MODE" = "hybrid" ] || [ "$SWAP_MODE" = "zram" ]; then
    if [ -b "/dev/block/zram0" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Configuring zRAM (${EXTENSION_SIZE_MB}MB)..." >> "$LOG_FILE"
        
        # Turn off existing zram if mounted
        swapoff /dev/block/zram0 2>/dev/null
        
        # Reset zRAM
        if [ -f "/sys/block/zram0/reset" ]; then
            echo 1 > /sys/block/zram0/reset 2>/dev/null
        fi
        
        # Select best compression algorithm if available
        if [ -f "/sys/block/zram0/comp_algorithm" ]; then
            if grep -q "zstd" /sys/block/zram0/comp_algorithm; then
                echo "zstd" > /sys/block/zram0/comp_algorithm 2>/dev/null
            elif grep -q "lz4" /sys/block/zram0/comp_algorithm; then
                echo "lz4" > /sys/block/zram0/comp_algorithm 2>/dev/null
            fi
        fi
        
        # Set disksize (e.g. 8192M)
        echo "${EXTENSION_SIZE_MB}M" > /sys/block/zram0/disksize 2>/dev/null
        
        # Format and enable with high priority (10)
        mkswap /dev/block/zram0 >/dev/null 2>&1
        swapon -p 10 /dev/block/zram0 >/dev/null 2>&1
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] zRAM activated at priority 10" >> "$LOG_FILE"
    fi
fi

# -------------------------------------------------------------
# 2. CONFIGURE STORAGE SWAP (For 'hybrid' or 'storage' modes)
# -------------------------------------------------------------
if [ "$SWAP_MODE" = "hybrid" ] || [ "$SWAP_MODE" = "storage" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Configuring Storage Swap (${EXTENSION_SIZE_MB}MB on /data)..." >> "$LOG_FILE"
    mkdir -p "$SWAP_DIR"
    chmod 700 "$SWAP_DIR"
    
    RECREATE=0
    if [ -f "$SWAP_FILE" ]; then
        CURRENT_SIZE_BYTES=$(stat -c%s "$SWAP_FILE" 2>/dev/null || stat -f%z "$SWAP_FILE" 2>/dev/null)
        [ -z "$CURRENT_SIZE_BYTES" ] && CURRENT_SIZE_BYTES=0
        CURRENT_SIZE_MB=$((CURRENT_SIZE_BYTES / 1048576))
        if [ "$CURRENT_SIZE_MB" -ne "$EXTENSION_SIZE_MB" ]; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Size mismatch (${CURRENT_SIZE_MB}MB != ${EXTENSION_SIZE_MB}MB). Recreating..." >> "$LOG_FILE"
            swapoff "$SWAP_FILE" 2>/dev/null
            rm -f "$SWAP_FILE"
            RECREATE=1
        fi
    else
        RECREATE=1
    fi

    if [ "$RECREATE" -eq 1 ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Creating ${EXTENSION_SIZE_MB}MB swapfile..." >> "$LOG_FILE"
        touch "$SWAP_FILE"
        chmod 600 "$SWAP_FILE"
        
        # Try fallocate first (fast), fallback to dd
        if ! fallocate -l "${EXTENSION_SIZE_MB}M" "$SWAP_FILE" 2>/dev/null; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] fallocate failed, creating via dd (this may take a few seconds)..." >> "$LOG_FILE"
            dd if=/dev/zero of="$SWAP_FILE" bs=1M count="$EXTENSION_SIZE_MB" 2>/dev/null
        fi
        
        mkswap "$SWAP_FILE" >/dev/null 2>&1
    fi

    # Mount storage swap with lower priority (5) so zRAM is used first
    if ! grep -q "$SWAP_FILE" /proc/swaps; then
        swapon -p 5 "$SWAP_FILE" >/dev/null 2>&1
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Storage swap mounted at priority 5" >> "$LOG_FILE"
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Storage swap already active" >> "$LOG_FILE"
    fi
fi

# -------------------------------------------------------------
# 3. KERNEL VM OPTIMIZATION
# -------------------------------------------------------------
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Applying Kernel VM Optimizations..." >> "$LOG_FILE"

# Swappiness
echo "$SWAPPINESS" > /proc/sys/vm/swappiness 2>/dev/null

# Page cluster (0 = read 1 page at a time, avoids SSD latency spikes)
echo "$PAGE_CLUSTER" > /proc/sys/vm/page-cluster 2>/dev/null

# Balanced VFS cache pressure
echo 100 > /proc/sys/vm/vfs_cache_pressure 2>/dev/null

# Smooth memory dirty writeback
echo 20 > /proc/sys/vm/dirty_ratio 2>/dev/null
echo 10 > /proc/sys/vm/dirty_background_ratio 2>/dev/null

# Compaction & stats
echo 20 > /proc/sys/vm/compaction_proactiveness 2>/dev/null
echo 10 > /proc/sys/vm/stat_interval 2>/dev/null

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Galaga RAM Booster successfully initialized." >> "$LOG_FILE"
cat /proc/swaps >> "$LOG_FILE" 2>&1

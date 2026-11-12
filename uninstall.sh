#!/system/bin/sh
# ==============================================================
# Nothing Galaga RAM Booster - Uninstallation Script
# Cleans up storage swap and resets VM parameters
# ==============================================================

SWAP_FILE="/data/swap/ram_booster.swap"

# Turn off and delete swap file to reclaim 8GB storage
if [ -f "$SWAP_FILE" ]; then
    swapoff "$SWAP_FILE" 2>/dev/null
    rm -f "$SWAP_FILE" 2>/dev/null
fi
rm -rf /data/swap 2>/dev/null

# Clean up log and config
rm -f /data/local/tmp/ram_booster.log 2>/dev/null

# Reset default swappiness and page-cluster
echo 60 > /proc/sys/vm/swappiness 2>/dev/null
echo 3 > /proc/sys/vm/page-cluster 2>/dev/null
echo 100 > /proc/sys/vm/vfs_cache_pressure 2>/dev/null

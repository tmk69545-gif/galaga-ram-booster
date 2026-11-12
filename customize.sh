#!/system/bin/sh
SKIPUNZIP=0

ui_print "**********************************************"
ui_print "*      NOTHING GALAGA RAM BOOSTER (+8GB)     *"
ui_print "*   Stock RAM Expansion for Custom ROMs      *"
ui_print "**********************************************"
ui_print ""
ui_print "- Target Device: CMF Phone 2 Pro (Galaga)"
ui_print "- Target Expansion: 8GB Physical + 8GB Virtual RAM"
ui_print "- Setting up execution permissions..."

set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/uninstall.sh" 0 0 0755
if [ -f "$MODPATH/system/bin/ramboost" ]; then
    set_perm "$MODPATH/system/bin/ramboost" 0 0 0755
fi

# Create default configuration file if not already present
if [ ! -f /data/adb/ram_booster.conf ]; then
    ui_print "- Generating /data/adb/ram_booster.conf..."
    cat << 'EOF' > /data/adb/ram_booster.conf
# ==============================================================
# Nothing Galaga RAM Booster Configuration
# Location: /data/adb/ram_booster.conf
# ==============================================================

# Extension size in Megabytes (8192 MB = +8GB Virtual RAM)
EXTENSION_SIZE_MB=8192

# SWAP_MODE choices:
#   hybrid  : 8GB zRAM (priority 10) + 8GB Storage Swapfile (priority 5)
#             Recommended for maximum multitasking and zero crash guarantee.
#   storage : 8GB UFS Flash Swapfile only (Exact replica of Stock Nothing OS)
#   zram    : 8GB Compressed In-RAM zRAM (Fastest, zero flash wear)
SWAP_MODE=hybrid

# Kernel Swappiness (Default: 130)
# Range: 0 to 200. Higher values use virtual RAM more actively.
SWAPPINESS=130

# Readahead cluster size (Default: 0 for flash/zram)
PAGE_CLUSTER=0
EOF
    set_perm /data/adb/ram_booster.conf 0 0 0644
    ui_print "- Default mode: Hybrid (+8GB Virtual RAM)"
else
    ui_print "- Existing configuration found at /data/adb/ram_booster.conf"
fi

ui_print ""
ui_print "[✓] Module installed successfully!"
ui_print "[i] After reboot, run 'su -c ramboost' in Termux to check status."
ui_print "[i] Please REBOOT your device now."

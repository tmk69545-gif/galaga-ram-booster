#!/usr/bin/env bash
set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_NAME="Galaga-RAM-Booster-v1.0.zip"
OUTPUT_DIR="${1:-$REPO_DIR/dist}"
if [[ "$OUTPUT_DIR" != /* ]]; then
  OUTPUT_DIR="$REPO_DIR/$OUTPUT_DIR"
fi

mkdir -p "$OUTPUT_DIR"
TARGET_ZIP="$OUTPUT_DIR/$OUTPUT_NAME"

echo "[*] Packaging module to: $TARGET_ZIP"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

cp "$REPO_DIR/module.prop" "$TMP_DIR/"
cp "$REPO_DIR/customize.sh" "$TMP_DIR/"
cp "$REPO_DIR/service.sh" "$TMP_DIR/"
cp "$REPO_DIR/uninstall.sh" "$TMP_DIR/"
cp "$REPO_DIR/README.md" "$TMP_DIR/"
cp -r "$REPO_DIR/META-INF" "$TMP_DIR/"
cp -r "$REPO_DIR/system" "$TMP_DIR/"
cp -r "$REPO_DIR/webroot" "$TMP_DIR/"

chmod 755 "$TMP_DIR/customize.sh" "$TMP_DIR/service.sh" "$TMP_DIR/uninstall.sh" "$TMP_DIR/system/bin/ramboost" "$TMP_DIR/META-INF/com/google/android/update-binary"
chmod 644 "$TMP_DIR/module.prop" "$TMP_DIR/README.md" "$TMP_DIR/webroot/index.html" "$TMP_DIR/META-INF/com/google/android/updater-script"

cd "$TMP_DIR"
zip -r -q "$TARGET_ZIP" .

echo "[+] Built successfully: $TARGET_ZIP"
ls -lh "$TARGET_ZIP"

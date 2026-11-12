#!/bin/bash
set -e
cd /tmp/ramhook_build

# 1. Compile Java
java -jar /tmp/ecj.jar -1.7 -cp "/tmp/android.jar:/tmp/ramhook_build/src" -d /tmp/ramhook_build/bin $(find /tmp/ramhook_build/src -name "*.java")

# 2. Dex with D8
java -cp /tmp/r8lib.jar com.android.tools.r8.D8 --output /tmp/ramhook_build/out --min-api 26 --lib /tmp/android.jar $(find /tmp/ramhook_build/bin -name "*.class")

# 3. Create APK with aapt2
/tmp/aapt2 link -o /tmp/ramhook_build/base.apk \
  -I /tmp/android.jar \
  --manifest /tmp/ramhook_build/AndroidManifest.xml \
  -R /tmp/ramhook_build/compiled/*.flat \
  --auto-add-overlay

# 4. Add classes.dex and assets
cd /tmp/ramhook_build
cp out/classes.dex .
zip -u base.apk classes.dex
zip -u -r base.apk assets/

# 5. Sign APK
java -jar /tmp/uber-apk-signer.jar --apks base.apk -o signed --overwrite

echo "BUILD SUCCESS"

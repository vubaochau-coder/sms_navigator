#!/bin/bash
set -e

# ==============================================================================
# In SHA-256 fingerprint của các khóa ký Android → giá trị cho biến môi trường
# ANDROID_CERT_SHA256 của server (assetlinks.json / App Links).
#
# Nguồn:
#   1. Debug keystore của máy này (~/.android/debug.keystore)
#   2. Upload/release keystore khai báo trong android/key.properties (nếu có)
#   3. APK truyền vào làm tham số (nếu có), ví dụ:
#        ./scripts/print_android_sha256.sh build/app/outputs/flutter-apk/app-release.apk
#
# Phát hành nội bộ (Firebase App Distribution): chỉ cần các SHA in ra ở đây.
# ==============================================================================

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KEY_PROPERTIES="$PROJECT_DIR/android/key.properties"

if ! command -v keytool >/dev/null 2>&1; then
  echo "❌ Không tìm thấy keytool (cài JDK hoặc dùng keytool trong Android Studio/jbr/bin)." >&2
  exit 1
fi

FINGERPRINTS=()

extract_sha256() {
  grep -E '^[[:space:]]*SHA256:' | head -1 | sed -E 's/^[[:space:]]*SHA256:[[:space:]]*//'
}

add() {
  local label="$1" sha="$2"
  if [ -n "$sha" ]; then
    echo "• $label: $sha"
    FINGERPRINTS+=("$sha")
  fi
}

prop() {
  grep -E "^[[:space:]]*$1[[:space:]]*=" "$KEY_PROPERTIES" | head -1 | sed -E "s/^[[:space:]]*$1[[:space:]]*=[[:space:]]*//"
}

# 1. Debug keystore
DEBUG_KEYSTORE="$HOME/.android/debug.keystore"
if [ -f "$DEBUG_KEYSTORE" ]; then
  add "Debug ($DEBUG_KEYSTORE)" "$(keytool -list -v -keystore "$DEBUG_KEYSTORE" \
    -alias androiddebugkey -storepass android -keypass android 2>/dev/null | extract_sha256)"
else
  echo "• Debug: chưa có $DEBUG_KEYSTORE (build debug một lần để Gradle tự tạo)"
fi

# 2. Release keystore từ key.properties
if [ -f "$KEY_PROPERTIES" ]; then
  STORE_FILE="$(prop storeFile)"
  # storeFile tương đối được Gradle resolve theo android/app/
  case "$STORE_FILE" in
    /*) ;;
    *) STORE_FILE="$PROJECT_DIR/android/app/$STORE_FILE" ;;
  esac
  add "Release ($STORE_FILE)" "$(keytool -list -v -keystore "$STORE_FILE" \
    -alias "$(prop keyAlias)" -storepass "$(prop storePassword)" 2>/dev/null | extract_sha256)"
else
  echo "• Release: chưa có android/key.properties → bản release đang ký bằng debug key"
fi

# 3. APK
if [ -n "$1" ]; then
  add "APK ($1)" "$(keytool -printcert -jarfile "$1" 2>/dev/null | extract_sha256)"
fi

if [ ${#FINGERPRINTS[@]} -eq 0 ]; then
  echo "❌ Không lấy được fingerprint nào." >&2
  exit 1
fi

echo "----------------------------------------------------------"
echo "ANDROID_CERT_SHA256 (dán vào Environment của server trên Render):"
printf '%s\n' "${FINGERPRINTS[@]}" | awk '!seen[$0]++' | paste -sd, -

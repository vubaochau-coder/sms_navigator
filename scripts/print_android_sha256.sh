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
    /* | [A-Za-z]:*) ;;
    *) STORE_FILE="$PROJECT_DIR/android/app/$STORE_FILE" ;;
  esac
  RELEASE_SHA="$(keytool -list -v -keystore "$STORE_FILE" \
    -alias "$(prop keyAlias)" -storepass "$(prop storePassword)" 2>/dev/null | extract_sha256)"
  add "Release ($STORE_FILE)" "$RELEASE_SHA"
else
  echo "• Release: chưa có android/key.properties → bản release đang ký bằng debug key"
fi

# apksigner: trên PATH, rồi build-tools mới nhất của Android SDK (biến môi
# trường, SDK của GitHub runner, vị trí mặc định, sdk.dir trong local.properties).
find_apksigner() {
  if command -v apksigner >/dev/null 2>&1; then
    command -v apksigner
    return
  fi
  local sdk dir
  for sdk in \
    "$ANDROID_HOME" "$ANDROID_SDK_ROOT" \
    "/usr/local/lib/android/sdk" \
    "$HOME/Android/Sdk" "$HOME/Library/Android/sdk" \
    "$(grep -E '^sdk\.dir=' "$PROJECT_DIR/android/local.properties" 2>/dev/null | sed 's/^sdk\.dir=//; s/\\:/:/g; s/\\\\/\//g')" \
    "${LOCALAPPDATA:+$LOCALAPPDATA/Android/Sdk}"; do
    [ -n "$sdk" ] && [ -d "$sdk/build-tools" ] || continue
    for dir in $(ls -1 "$sdk/build-tools" 2>/dev/null | sort -t. -k1,1nr -k2,2nr -k3,3nr); do
      for bin in apksigner apksigner.bat; do
        if [ -f "$sdk/build-tools/$dir/$bin" ]; then
          echo "$sdk/build-tools/$dir/$bin"
          return
        fi
      done
    done
  done
  # Fallback tìm kiếm nhanh trong hệ thống
  find /usr/local/lib/android/sdk/build-tools -name apksigner 2>/dev/null | head -1
}

# 3. APK — Flutter đặt minSdk 24 nên APK chỉ có chữ ký v2/v3: `keytool
# -printcert -jarfile` báo "Not a signed jar file", phải dùng apksigner.
if [ -n "$1" ]; then
  if [ ! -f "$1" ]; then
    echo "❌ Không thấy APK: $1" >&2
    exit 1
  fi
  APKSIGNER="$(find_apksigner)"
  if [ -n "$APKSIGNER" ]; then
    # build-tools ≤ 36: "Signer #1 certificate SHA-256 digest: …"
    # build-tools 37+:  "V2 Signer: certificate SHA-256 digest: …"
    APK_SHA="$("$APKSIGNER" verify --print-certs "$1" 2>/dev/null \
      | grep -E 'certificate SHA-256 digest:' | head -1 | awk '{print $NF}' \
      | tr 'a-f' 'A-F' | sed -E 's/(..)/\1:/g; s/:$//')"
  else
    # APK cũ có chữ ký v1 vẫn đọc được bằng keytool
    APK_SHA="$(keytool -printcert -jarfile "$1" 2>/dev/null | extract_sha256)"
  fi
  if [ -z "$APK_SHA" ]; then
    if [ -n "$APKSIGNER" ]; then
      echo "❌ Không đọc được chữ ký của $1 bằng $APKSIGNER." >&2
    else
      echo "❌ Không đọc được chữ ký của $1 (không tìm thấy apksigner trong Android SDK build-tools)." >&2
    fi
    exit 1
  fi
  add "APK ($1)" "$APK_SHA"
  if [ -n "$RELEASE_SHA" ] && [ "$APK_SHA" = "$RELEASE_SHA" ]; then
    echo "  ✅ APK ký bằng release keystore"
  elif [ -n "$RELEASE_SHA" ]; then
    echo "  ⚠️  APK KHÔNG ký bằng release keystore trong android/key.properties"
  fi
fi

if [ ${#FINGERPRINTS[@]} -eq 0 ]; then
  echo "❌ Không lấy được fingerprint nào." >&2
  exit 1
fi

echo "----------------------------------------------------------"
echo "ANDROID_CERT_SHA256 (dán vào Environment của server trên Render):"
printf '%s\n' "${FINGERPRINTS[@]}" | awk '!seen[$0]++' | paste -sd, -

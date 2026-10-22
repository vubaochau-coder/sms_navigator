#!/bin/bash
set -e

# ==============================================================================
# Tạo keystore ký bản phát hành nội bộ (Firebase App Distribution) + ghi
# android/key.properties, rồi in SHA-256 cho ANDROID_CERT_SHA256 của server.
#
# Chạy MỘT LẦN trên máy build:
#   ./scripts/create_release_keystore.sh [đường_dẫn_keystore]
# Mặc định: ~/.android/sms-navigator-release.jks
#
# Sau khi chạy: SAO LƯU file .jks + android/key.properties (password manager /
# ổ cloud riêng). Mất keystore = bản sau không cập nhật đè được bản đã cài →
# mọi máy phải gỡ app (mất khóa nếu chưa sao lưu trong app).
# ==============================================================================

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KEY_PROPERTIES="$PROJECT_DIR/android/key.properties"
KEYSTORE="${1:-$HOME/.android/sms-navigator-release.jks}"
ALIAS="upload"

if ! command -v keytool >/dev/null 2>&1; then
  echo "❌ Không tìm thấy keytool (cài JDK hoặc dùng keytool trong Android Studio/jbr/bin)." >&2
  exit 1
fi
if [ -f "$KEY_PROPERTIES" ]; then
  echo "❌ Đã có $KEY_PROPERTIES — không ghi đè. Xoá file đó nếu thật sự muốn tạo key mới." >&2
  exit 1
fi
if [ -f "$KEYSTORE" ]; then
  echo "❌ Đã có $KEYSTORE — không ghi đè keystore đang dùng." >&2
  exit 1
fi

# PKCS12: mật khẩu store và key phải giống nhau
PASSWORD="$(LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 32)"

mkdir -p "$(dirname "$KEYSTORE")"
keytool -genkeypair -v \
  -keystore "$KEYSTORE" -storetype PKCS12 \
  -alias "$ALIAS" -keyalg RSA -keysize 2048 -validity 10000 \
  -storepass "$PASSWORD" -keypass "$PASSWORD" \
  -dname "CN=SMS Navigator, OU=Internal" >/dev/null 2>&1
chmod 600 "$KEYSTORE"

# Gradle trên Windows không hiểu đường dẫn kiểu Git Bash (/c/Users/...)
STORE_FILE="$KEYSTORE"
if command -v cygpath >/dev/null 2>&1; then
  STORE_FILE="$(cygpath -m "$KEYSTORE")"
fi

cat > "$KEY_PROPERTIES" <<EOF
# Sinh bởi scripts/create_release_keystore.sh — KHÔNG commit (đã gitignore).
storePassword=$PASSWORD
keyPassword=$PASSWORD
keyAlias=$ALIAS
storeFile=$STORE_FILE
EOF
chmod 600 "$KEY_PROPERTIES"

echo "✅ Đã tạo keystore: $KEYSTORE"
echo "✅ Đã ghi:          $KEY_PROPERTIES"
echo "----------------------------------------------------------"
"$PROJECT_DIR/scripts/print_android_sha256.sh"
echo "----------------------------------------------------------"
echo "⚠️  Sao lưu NGAY 2 file trên (mật khẩu nằm trong key.properties)."
echo "    Build trên máy khác: chép cả 2 file, sửa storeFile cho đúng đường dẫn."

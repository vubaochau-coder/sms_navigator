#!/bin/bash
# Build APK release và gửi lên Firebase App Distribution.
# Release notes = tiêu đề commit cuối cùng. Version lấy nguyên từ pubspec.yaml
# (tăng build number bằng commit riêng trước khi chạy).
#
#   ./scripts/distribute.sh                 # nhóm internal-dev
#   ./scripts/distribute.sh field-testers   # nhóm khác
set -euo pipefail
cd "$(dirname "$0")/.."

GROUPS_="${1:-internal-dev}"
APK="build/app/outputs/flutter-apk/app-release.apk"
VERSION=$(sed -n 's/^version:[[:space:]]*//p' pubspec.yaml)
NOTES="[v$VERSION] $(git log -1 --pretty=%s)"

# Không có keystore → APK ký bằng debug key, không cài đè được bản cũ.
[ -f android/key.properties ] || { echo "❌ Thiếu android/key.properties (release keystore)"; exit 1; }

echo "📦 v$VERSION → $GROUPS_"
echo "📝 $NOTES"

fvm flutter build apk --release

npx -y firebase-tools@latest appdistribution:distribute "$APK" \
  --app "1:510867121628:android:8e0205deb80aa79c565b19" \
  --project "sms-navigator-relay-81229" \
  --groups "$GROUPS_" \
  --release-notes "$NOTES"

echo "🎉 Đã phân phối v$VERSION"

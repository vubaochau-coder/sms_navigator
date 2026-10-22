#!/bin/bash
# Tăng build number → build APK release → gửi Firebase App Distribution
# → commit pubspec.yaml. Release notes = tiêu đề commit cuối cùng.
# Build/upload lỗi thì pubspec.yaml được trả về như cũ, không commit gì.
#
#   ./scripts/distribute.sh                 # nhóm internal-dev
#   ./scripts/distribute.sh field-testers   # nhóm khác
set -euo pipefail
cd "$(dirname "$0")/.."

GROUPS_="${1:-internal-dev}"
APK="build/app/outputs/flutter-apk/app-release.apk"

# Không có keystore → APK ký bằng debug key, không cài đè được bản cũ.
[ -f android/key.properties ] || { echo "❌ Thiếu android/key.properties (release keystore)"; exit 1; }
git diff --quiet -- pubspec.yaml || { echo "❌ pubspec.yaml đang có thay đổi chưa commit"; exit 1; }

OLD=$(sed -n 's/^version:[[:space:]]*//p' pubspec.yaml)
NAME=${OLD%%+*}
BUILD=${OLD#*+}; [ "$BUILD" = "$OLD" ] && BUILD=0
VERSION="$NAME+$((BUILD + 1))"
NOTES="[v$VERSION] $(git log -1 --pretty=%s)"

sed -i.bak "s/^version:.*/version: $VERSION/" pubspec.yaml && rm pubspec.yaml.bak
trap 'git checkout -- pubspec.yaml; echo "❌ Lỗi — đã trả pubspec.yaml về $OLD"' ERR

echo "📦 $OLD → $VERSION ($GROUPS_)"
echo "📝 $NOTES"

fvm flutter build apk --release

npx -y firebase-tools@latest appdistribution:distribute "$APK" \
  --app "1:510867121628:android:8e0205deb80aa79c565b19" \
  --project "sms-navigator-relay-81229" \
  --groups "$GROUPS_" \
  --release-notes "$NOTES"

trap - ERR
git commit -q -m "chore(release): bump to $VERSION" -- pubspec.yaml
echo "🎉 Đã phân phối và commit v$VERSION (nhớ git push)"

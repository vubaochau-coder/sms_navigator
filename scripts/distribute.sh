#!/bin/bash
# Tăng build number → build APK release → gửi Firebase App Distribution
# → commit pubspec.yaml. Release notes = tiêu đề commit cuối cùng.
# Build/upload lỗi thì pubspec.yaml được trả về như cũ, không commit gì.
#
# Build number mới = max(pubspec, bản mới nhất trên Firebase) + 1, giống
# distribute.yml, để bản phát hành từ máy và từ CI không trùng số. Hỏi
# Firebase cần gcloud đã đăng nhập (`gcloud auth login`); không có thì chỉ
# dựa vào pubspec.yaml.
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

LATEST=""
if TOKEN=$(gcloud auth print-access-token 2>/dev/null); then
  LATEST=$(curl -sf -H "Authorization: Bearer $TOKEN" \
    "https://firebaseappdistribution.googleapis.com/v1/projects/510867121628/apps/1:510867121628:android:8e0205deb80aa79c565b19/releases?pageSize=1" \
    | grep -oE '"buildVersion": *"[0-9]+"' | grep -oE '[0-9]+' | head -1 || true)
fi
if [ -n "$LATEST" ]; then
  echo "🔥 Firebase: build mới nhất = $LATEST"
  [ "$LATEST" -gt "$BUILD" ] && BUILD=$LATEST
else
  echo "⚠️  Không hỏi được Firebase (cần gcloud đã đăng nhập) — dùng build number trong pubspec.yaml"
fi
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

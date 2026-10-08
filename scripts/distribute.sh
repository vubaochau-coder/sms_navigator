#!/bin/bash
set -e

# Chuyển về đúng thư mục gốc của project sms_navigator
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$DIR"

PUBSPEC_FILE="pubspec.yaml"
APP_ID="1:510867121628:android:8e0205deb80aa79c565b19"
PROJECT_ID="sms-navigator-relay-81229"
TESTER_GROUPS="${1:-"internal-dev"}"
APK_PATH="build/app/outputs/flutter-apk/app-release.apk"

# Đọc version hiện tại từ pubspec.yaml
CURRENT_LINE=$(grep "^version:" "$PUBSPEC_FILE")
CURRENT_VERSION_RAW=$(echo "$CURRENT_LINE" | sed 's/version:[[:space:]]*//')

# Tách version name và build number (ví dụ 1.0.0+15)
VERSION_NAME=$(echo "$CURRENT_VERSION_RAW" | cut -d'+' -f1)
BUILD_NUMBER=$(echo "$CURRENT_VERSION_RAW" | cut -s -d'+' -f2)

# Tăng build number lên 1
if [ -z "$BUILD_NUMBER" ]; then
  NEW_BUILD=1
else
  NEW_BUILD=$((BUILD_NUMBER + 1))
fi

NEW_VERSION="${VERSION_NAME}+$NEW_BUILD"

# Tự động cập nhật phiên bản mới vào pubspec.yaml
perl -i -pe "s/^version:.*/version: $NEW_VERSION/" "$PUBSPEC_FILE"

# Lấy commit message gần nhất làm release notes
COMMIT_MSG=$(git log -1 --pretty=%B | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
RELEASE_NOTES="[v${VERSION_NAME}+$NEW_BUILD] $COMMIT_MSG"

echo "=========================================="
echo "📦 SMS NAVIGATOR - DISTRIBUTE TO FIREBASE"
echo "=========================================="
echo "🏷️  Version: ${VERSION_NAME} (Build number: $NEW_BUILD)"
echo "👥 Nhóm Tester: $TESTER_GROUPS"
echo "📝 Release Notes:"
echo "$RELEASE_NOTES"
echo "------------------------------------------"

echo "🔨 [1/2] Đang build Flutter APK (Release)..."
fvm flutter build apk --release

if [ ! -f "$APK_PATH" ]; then
  echo "❌ Lỗi: Không tìm thấy file APK tại $APK_PATH"
  exit 1
fi

echo "🚀 [2/2] Đang tải APK lên Firebase App Distribution & phân phối cho tester ($TESTER_GROUPS)..."
firebase appdistribution:distribute "$APK_PATH" \
  --app "$APP_ID" \
  --project "$PROJECT_ID" \
  --groups "$TESTER_GROUPS" \
  --release-notes "$RELEASE_NOTES"

echo "=========================================="
echo "🎉 PHÂN PHỐI THÀNH CÔNG: v${VERSION_NAME}+$NEW_BUILD"
echo "👉 Thông báo đã được tự động gửi tới nhóm tester '$TESTER_GROUPS' qua Firebase App Tester!"
echo "=========================================="

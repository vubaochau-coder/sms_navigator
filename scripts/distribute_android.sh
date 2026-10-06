#!/bin/bash
set -e

# ==============================================================================
# Script phân phối bản build Android lên Firebase App Distribution
# Dự án: SMS Navigator (sms-navigator-relay-81229)
# ==============================================================================

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

FIREBASE_APP_ID="1:510867121628:android:8e0205deb80aa79c565b19"
PROJECT_ID="sms-navigator-relay-81229"

RELEASE_NOTES="${1:-"Bản cập nhật tính năng: Ghép đôi bằng QR Code E2EE & In-App Scanner"}"
TESTER_GROUPS="${2:-"internal-dev"}"

echo "=========================================================="
echo "🚀 BẮT ĐẦU QUY TRÌNH PHÂN PHỐI QUA FIREBASE APP TESTER"
echo "=========================================================="
echo "• Project ID:    $PROJECT_ID"
echo "• App ID:        $FIREBASE_APP_ID"
echo "• Nhóm Tester:   $TESTER_GROUPS"
echo "• Release Notes: $RELEASE_NOTES"
echo "----------------------------------------------------------"

echo "🔨 [1/3] Đang biên dịch Release APK..."
fvm flutter build apk --release

APK_PATH="build/app/outputs/flutter-apk/app-release.apk"

if [ ! -f "$APK_PATH" ]; then
  echo "❌ Lỗi: Không tìm thấy file APK tại: $APK_PATH"
  exit 1
fi

echo "📤 [2/3] Đang tải lên Firebase App Distribution..."
npx -y firebase-tools@latest appdistribution:distribute "$APK_PATH" \
  --app "$FIREBASE_APP_ID" \
  --project "$PROJECT_ID" \
  --groups "$TESTER_GROUPS" \
  --release-notes "$RELEASE_NOTES"

echo "----------------------------------------------------------"
echo "🎉 [3/3] HOÀN TẤT PHÂN PHỐI THÀNH CÔNG!"
echo "👉 Tester trong nhóm '$TESTER_GROUPS' sẽ nhận được thông báo trên ứng dụng Firebase App Tester."
echo "👉 Console quản lý: https://console.firebase.google.com/project/$PROJECT_ID/appdistribution"
echo "=========================================================="

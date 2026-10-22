# BACKLOG — các hạng mục chưa làm (Mobile / Flutter + Kotlin)

> Tài liệu gom toàn bộ nợ kỹ thuật + roadmap chưa triển khai của phía mobile.
> Mục đã hoàn thành bị loại khỏi danh sách; hoàn thành mục nào thì xoá mục đó.
> App chỉ hỗ trợ **Android** — không làm hạng mục iOS. Phát hành **nội bộ qua Firebase App Distribution**, không lên Google Play.
> Cập nhật lần cuối: 22/10/2026.

---

## 0. Kiểm thử & phát hành

Nhánh đang chờ merge: `feat/otp-notification` (cả mobile và BE — gồm 1.2, 1.3, 1.1, 2.1 và dọn backlog).

| # | Hạng mục | Ghi chú | Ưu tiên |
|---|---|---|---|
| 0.2 | Thứ tự phát hành: cài app mới lên các máy Android **rồi** mới merge BE `feat/otp-notification` vào `main` (Render tự deploy) | App cũ không hiện thông báo khi chạy nền nếu BE gửi `NEW_MESSAGE` data-only | P0 |
| 0.3b | Chuyển các máy sang keystore release: cài **1.0.1+19** (nhánh `release/1.0.1-export`, luôn ký debug key cũ → cài đè, giữ dữ liệu) → **Sao lưu** → gỡ app → cài **1.1.0+20** (`main`, ký release keystore) → **Khôi phục** | Máy build bản 1.0.1 phải là máy đã build bản đang cài (cùng `~/.android/debug.keystore`), nếu không cài đè sẽ báo `INSTALL_FAILED_UPDATE_INCOMPATIBLE`. Keystore release: `./scripts/create_release_keystore.sh`, nhớ sao lưu `.jks` + `android/key.properties` | P0 |
| 0.5 | Test thực tế trên máy | Deeplink cold start / mid-splash / warm start; 2 kênh Owner cùng khớp 1 SMS; revoke khi bật máy bay (pending key + self-heal); OTP trong thông báo khi app bị vuốt tắt; **sao lưu → gỡ app → cài lại → khôi phục** (Owner relay tiếp được, Member đọc được tin cũ) | P0 |

---

## 1. Tính năng mới

| # | Hạng mục | Chi tiết kỹ thuật & Hướng giải quyết | Ưu tiên |
|---|---|---|---|

---

## 2. Bảo mật native (Android)

| # | Hạng mục | Chi tiết | Ưu tiên |
|---|---|---|---|

---

## 3. Nợ kỹ thuật

| # | Hạng mục | Chi tiết | Ưu tiên |
|---|---|---|---|
| 3.11 | Chuyển sang Built-in Kotlin (AGP 9) | Sau 3.10 Flutter cảnh báo app còn áp `kotlin-android` (KGP) và các plugin `firebase_*`, `shared_preferences_android` cũng vậy → sẽ lỗi build ở bản Flutter sau. Đang giữ `android.builtInKotlin=false` / `android.newDsl=false`. Làm khi các plugin ra bản hỗ trợ: bỏ plugin KGP, bật 2 cờ, nâng plugin. | P3 |

---

## 4. Hạng mục đã hoàn thành (tham khảo — đừng làm lại)

- **Nhánh `feat/backlog-sweep`** (xem `REVIEW_BACKLOG.md` để kiểm thử):
  - `distribute.yml` ký bằng release keystore từ GitHub Secrets (`ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`), dừng nếu thiếu secret, kiểm tra chữ ký APK trước khi upload; thêm `flutter analyze`, ghim Flutter 3.47.7 — cũ: mục 3.8.
  - CI pull request `.github/workflows/ci.yml`: kiểm l10n đã sinh, `flutter analyze`, `flutter test`, Kotlin `:app:testDebugUnitTest` — cũ: mục 3.9.
  - Clean-cut v4 phía app: gỡ `InvitePayload`, `LegacyInviteLink`, `JoinResolveStarted`, resolve/claim bằng token; chỉ còn luồng opaque QR (`QrEntryPage` → `JoinConfirmPage.fromQr`) — cũ: mục 0.6. Phát hành sau force update `app_update_min_build` = 20 và BE clean-cut.
  - Đổi tên kênh (Owner): menu ⋮ trên chi tiết kênh → dialog → `PUT /channels/name` → refresh + đồng bộ tên xuống native relay — cũ: mục 1.5.
  - Rời kênh (member) / giải tán kênh (owner) từ menu ⋮; Owner tự xoay khóa khi có member rời (`rotation_pending` trong `SyncOwnerRelayChannelUseCase`); danh sách kênh tự làm mới khi quay về — cũ: mục 1.4.
  - Lịch sử yêu cầu kết nối đã xử lý (Owner): menu ⋮ → màn lịch sử, phân trang "Xem thêm" — cũ: mục 1.6.
  - Nhắc sao lưu: banner trên tab Kênh khi có kênh chưa nằm trong bản sao lưu / khôi phục gần nhất, "Để sau" 3 ngày — cũ: mục 1.9.
  - Keystore lỗi: native ghi lại mỗi lần lưu thô (`VaultFallbackLog`), app báo Crashlytics non-fatal + cảnh báo lúc khởi động (vẫn fail-open để relay không dừng) — cũ: mục 2.2.
  - Xử lý 401 tập trung: `ApiClient.onUnauthorized` → `DeviceSessionRecovery` (đăng ký lại cùng device_id, cập nhật native, retry 1 lần); worker native park SMS khi 401 — cũ: mục 3.2.
  - Tuỳ chọn "Thông báo cả tin máy này chuyển tiếp" (mặc định tắt) trong trang thiết bị, áp dụng cả foreground lẫn background handler — cũ: mục 1.8.
  - Cache tin nhắn offline: lưu ciphertext (E2EE at rest) 14 ngày, mất mạng thì giải mã lại bản lưu và hiện "Ngoại tuyến — đang xem bản lưu lúc …" — cũ: mục 1.7.
  - TD-3: luồng khởi động tách vào `StartupRepository`/`StartupRepositoryImpl`; `SplashBloc` chỉ phụ thuộc repository (3.3).
  - Startup gate: `StartupGate`/`RemoteConfigStartupGate` (`maintenance_enabled`, `maintenance_message`, fail-open) chặn khởi động khi bảo trì; CapabilitySet/StartupCoordinator bỏ — chưa có nhu cầu (3.5).
  - Gradle 9.1.0 / AGP 9.0.1 / Kotlin 2.3.20; `kotlinOptions` → `kotlin { compilerOptions }`. APK release: chữ ký và manifest không đổi (3.10).
- **22/10/2026** (merge `ccr-41b49984-c6ug2s` → `feat/otp-notification`):
  - Đã chạy trên nhánh này: `flutter gen-l10n` (sinh lại file l10n đã cũ), `flutter analyze` (sạch), `flutter test` (352/352), `./gradlew :app:testDebugUnitTest` (103/103), `flutter build apk --debug` thành công — cũ: mục 0.1. Sửa `device_profile_page_test` thiếu `BackupRepository` sau 1.1.
  - Cloudflare Worker chuyển tiếp nguyên `/.well-known/*` và `/qr/*` (200, không redirect) — cũ: mục 0.4. 
  - `flutter_test_config.dart`: chặn theo host đích thay vì proxy (proxy loopback `HTTPS_PROXY` từng làm request lọt ra ngoài) + test bảo vệ.
  - App Links: `ANDROID_CERT_SHA256` (release `4C:A4:…:C3:42` + debug máy build) trên Render; máy test cài APK release báo `verified` cho `sms-relay.hirusakunasaga.workers.dev` — cũ: mục 0.3. `print_android_sha256.sh` đọc chữ ký APK bằng `apksigner` (APK minSdk 24 chỉ có chữ ký v2/v3).
  - Release signing đọc `android/key.properties` + `scripts/print_android_sha256.sh`; hướng dẫn chạy test trong `AGENTS.md` §8.
- **Nhánh `feat/otp-notification`** (chưa merge) — sao lưu & outbox native:
  - 1.1 Sao lưu / khôi phục: file `.smsnav` = AES-256-GCM, key từ PBKDF2-HMAC-SHA256 (310k vòng, salt 16B, chạy ngoài UI isolate), AAD `smsnav-backup|v1`. Chứa identity X25519, mọi channel key theo epoch, `device_id`, `device_token`, tên, server URL. Tạo ở **Hồ sơ thiết bị → Sao lưu**; khôi phục ở **Splash lần đầu** ("Thiết lập thiết bị mới" / "Khôi phục từ bản sao lưu"). Lưu/mở file qua Storage Access Framework (`BackupFileChannel.kt`, không thêm package, không cần quyền bộ nhớ). Ghi device token **sau cùng** khi khôi phục (bị kill giữa chừng → lần sau vẫn được mời khôi phục).
  - Nợ kỹ thuật (không đổi nghiệp vụ): 3.1 `test/flutter_test_config.dart` chặn mọi kết nối ra ngoài loopback (test không chạm server production); 3.4 startup reconcile bỏ qua kênh đã có key cho `current_epoch` (0 request), bỏ `getChannelDetail` trùng, không provision 2 lần kênh vừa duyệt, chạy song song tối đa 4 (`forEachBounded`) — sync whitelist của Owner cũng song song; 3.6 `SplashFailureKind` thay cho đoán lỗi qua chuỗi; 3.7 `AppStrings.defaultDeviceName` + test khớp l10n.
  - 2.1 SMS không còn nằm plaintext trong DB của WorkManager: text + sender vào outbox mã hoá của `RelayChannelStore`, worker chỉ nhận `outbox_id`; xoá khi job kết thúc, giữ khi retry; TTL 24h + giới hạn 200. Job do bản cũ enqueue vẫn chạy.
- **Nhánh `feat/otp-notification`** (mobile + BE, chưa merge):
  - 1.2 OTP ngay trong thông báo (Android): BE gửi `NEW_MESSAGE` **data-only** kèm `sequence_number`, `sender_device_id` (vẫn không có ciphertext — I5); app gọi `GET /api/v2/channels/message` (§6.4), giải mã cục bộ, hiện "Mã OTP: …" + nút **"Sao chép"** (`OtpCodeExtractor` tách mã; không tách được thì chép cả tin). Lỗi bất kỳ → thông báo chung. Bỏ qua tin do chính máy relay. Màn hình khoá: `visibility: private`.
  - 1.3 `SmsPage` tự làm mới ngầm (không shimmer, không toast lỗi) khi có `NEW_MESSAGE` (chỉ khi đang xem hôm nay), `APPROVED` / `REVOKED` (mọi ngày), khi chạm thông báo, và khi app quay lại foreground.
  - `FcmNotificationService.channelEvents` (Stream) thay cho `setChannelEventListener`.

- **Đợt 21/10/2026** (đã merge `main`):
  - Relay đa kênh: `RelayChannelStore`, mỗi SMS áp whitelist từng kênh và có worker riêng; xoay khóa stage → commit → promote, worker tự phục hồi 409 `EPOCH_OUTDATED`, SMS chờ khóa được park + gửi lại.
  - Universal Opaque QR v3.3: `QrLinkParser`, `QrIngressCubit` (pending deeplink one-shot), `QrEntryPage`, claim bằng `code`, App Links + custom scheme, nút "Dán mã" (không đọc clipboard tự động), Owner render `qr_url`.
  - Whitelist theo từng kênh + định tuyến SMS native theo kênh (cũ: mục 4.3).
  - Deeplink App Links & custom scheme (cũ: mục 4.1).
  - Gom chuỗi hardcode về `app_vi.arb`; `AppL10n.current` cho BLoC/service/FCM background.
  - Tổ chức lại `lib/core` (`ui/`, `crypto/`, `usecases/`, `bloc/qr_ingress/`); giải mã SMS theo lô + cache key, lô lớn chạy `Isolate.run`; giảm rebuild BLoC.
- Kiến trúc V2 channel 1-to-N E2EE (đập bỏ V1 pairing/relay) — xem `../sms_navigator_server/SERVER_API_SPEC.md`.
- Xoá toàn bộ tàn dư V1 + dead code (`isRelayEnabled`, method channel chết, banner orphan, endpoints V1).
- FCM chuông V2: notification block cho `NEW_MESSAGE` / `JOIN_REQUEST` / `APPROVED` / `REVOKED` kèm `channel_name`.
- Auto device name từ native (`Settings.Global.DEVICE_NAME` → `bluetooth_name` → `Build` fallback) + auto-heal máy cũ (`commit d2b2a14`).
- Shimmer loading đồng bộ + pull-to-refresh phản hồi tức thì (`commit dde4e5b`, `59c3fb6`).
- Đóng gói & phân phối APK qua Firebase App Distribution (`scripts/distribute_android.sh`).

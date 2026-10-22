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
| 0.3 | Điền `ANDROID_CERT_SHA256` trên Render — giá trị in ra bởi `./scripts/create_release_keystore.sh` (hoặc `./scripts/print_android_sha256.sh`), gồm SHA release + debug của máy build; kiểm tra `adb shell pm get-app-links com.example.sms_navigator` | Thiếu → link `https://…/qr/<code>` không tự mở app | P0 |
| 0.3b | Chuyển sang keystore release riêng: chạy `./scripts/create_release_keystore.sh` trên máy build, **sao lưu** `.jks` + `android/key.properties` | Đổi chữ ký → các máy đã cài phải gỡ app một lần: cài bản PR #1 → **sao lưu trong app** → gỡ → cài bản ký key mới → **khôi phục** (trùng kịch bản test 0.5). Làm trước khi có thêm người dùng | P0 |
| 0.5 | Test thực tế trên máy | Deeplink cold start / mid-splash / warm start; 2 kênh Owner cùng khớp 1 SMS; revoke khi bật máy bay (pending key + self-heal); OTP trong thông báo khi app bị vuốt tắt; **sao lưu → gỡ app → cài lại → khôi phục** (Owner relay tiếp được, Member đọc được tin cũ) | P0 |
| 0.6 | Roadmap GĐ6 — clean-cut v4: phát hành app mới → bật `min_version` force update → BE gỡ `pairing_token`, `invite_url` v4, `/channels/sessions/resolve`, claim bằng token → app gỡ `InvitePayload`, `LegacyInviteLink`, `JoinResolveStarted` | Thứ tự bắt buộc: không gỡ v4 trước khi force update | P1 |

---

## 1. Tính năng mới

| # | Hạng mục | Chi tiết kỹ thuật & Hướng giải quyết | Ưu tiên |
|---|---|---|---|
| 1.4 | Quản lý vòng đời kênh | Member tự rời kênh (`leave`); Owner lưu trữ / giải tán kênh (`archive`). Cần endpoint BE (BE BACKLOG 2.2). | P2 |
| 1.5 | Đổi tên kênh | Owner, dialog 1–50 ký tự, `PUT /api/v2/channels/name` (BE BACKLOG 2.1, chưa có). Cập nhật `RelayChannelStore` qua `SyncOwnerRelayChannelUseCase`. | P2 |
| 1.6 | Lịch sử yêu cầu kết nối đã xử lý (Owner) | Xem lại request `APPROVED` / `REJECTED` / `CANCELLED`. | P2 |
| 1.7 | Offline encrypted cache tin nhắn | Tin nhắn chỉ fetch online theo ngày; cân nhắc lưu local mã hóa nếu cần xem khi mất mạng. | P3 |
| 1.8 | Bỏ thông báo cho chính máy relay có thể cấu hình | 1.2 bỏ qua `NEW_MESSAGE` do chính máy gửi (Owner đã có SMS gốc). Nếu cần: thêm tuỳ chọn bật lại. | P3 |
| 1.9 | Nhắc tạo bản sao lưu | Owner chưa từng sao lưu (hoặc vừa tạo/tham gia kênh mới sau lần sao lưu cuối) → banner nhắc. Bản sao lưu cũ không chứa key của epoch mới, nhưng vẫn khôi phục được danh tính → `StartupReconcile` tự lấy lại envelope epoch mới. | P2 |

---

## 2. Bảo mật native (Android)

| # | Hạng mục | Chi tiết | Ưu tiên |
|---|---|---|---|
| 2.2 | Fallback lưu plaintext khi Keystore lỗi | `OtpPreferences` (device token) và `RelayChannelStore` (channel key, parked queue, outbox SMS) lưu thô nếu `SecureVault` ném lỗi. Ít nhất log/Crashlytics + cảnh báo; cân nhắc fail-closed. | P2 |

---

## 3. Nợ kỹ thuật

| # | Hạng mục | Chi tiết | Ưu tiên |
|---|---|---|---|
| 3.2 | Xử lý 401 tập trung | `ApiClient` chỉ ném `UnauthorizedException`; chưa có luồng tự đăng ký lại / báo người dùng thống nhất ngoài Splash. | P2 |
| 3.3 | **TD-3 — Tách luồng khởi động** | `SplashBloc` inject trực tiếp 7 services. Gom vào `StartupRepository.bootstrap(...)`; `SplashBloc` chỉ phụ thuộc repository. Nên làm cùng startup capability gate (3.5). | P3 |
| 3.5 | Startup capability gate (`MaintenanceGate`, …) | Phần còn lại của roadmap startup cũ: `CapabilitySet`, `StartupGate`, `StartupCoordinator`. (Pending deeplink đã có qua `QrIngressCubit`.) | P3 |

---

## 4. Hạng mục đã hoàn thành (tham khảo — đừng làm lại)

- **22/10/2026** (merge `ccr-41b49984-c6ug2s` → `feat/otp-notification`):
  - Đã chạy trên nhánh này: `flutter gen-l10n` (sinh lại file l10n đã cũ), `flutter analyze` (sạch), `flutter test` (352/352), `./gradlew :app:testDebugUnitTest` (103/103), `flutter build apk --debug` thành công — cũ: mục 0.1. Sửa `device_profile_page_test` thiếu `BackupRepository` sau 1.1.
  - Cloudflare Worker chuyển tiếp nguyên `/.well-known/*` và `/qr/*` (200, không redirect) — cũ: mục 0.4. Production `assetlinks.json` vẫn `[]` (xem 0.3).
  - `flutter_test_config.dart`: chặn theo host đích thay vì proxy (proxy loopback `HTTPS_PROXY` từng làm request lọt ra ngoài) + test bảo vệ.
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

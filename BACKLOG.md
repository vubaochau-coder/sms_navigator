# BACKLOG — các hạng mục chưa làm (Mobile / Flutter + Kotlin)

> Tài liệu gom toàn bộ nợ kỹ thuật + roadmap chưa triển khai của phía mobile.
> Mục đã hoàn thành bị loại khỏi danh sách; hoàn thành mục nào thì xoá mục đó.
> Cập nhật lần cuối: 22/10/2026.

---

## 0. Việc dở dang của đợt cập nhật lớn (QR v3.3 + relay đa kênh)

Code đã xong trên các nhánh `refactor/multi-channel-relay` → `feat/opaque-qr` → `chore/l10n-backlog`
(BE: `refactor/idempotent-rotation` → `feat/opaque-qr`). Còn lại:

| # | Hạng mục | Ghi chú | Ưu tiên |
|---|---|---|---|
| 0.2 | Điền `ANDROID_CERT_SHA256` cho server (production hiện trả `assetlinks.json` = `[]`); kiểm tra `adb shell pm get-app-links com.example.sms_navigator` | Lấy giá trị bằng `./scripts/print_android_sha256.sh` (debug keystore + release keystore trong `android/key.properties` + APK tuỳ chọn), cộng SHA "App signing key" trong Play Console nếu phát hành qua Play. Lưu ý: chưa có `key.properties` thì release vẫn ký bằng debug key của **máy build** → đổi máy build là đổi SHA. Thiếu → link `https://…/qr/<code>` không tự mở app | P0 |
| 0.2b | Tạo upload keystore release + `android/key.properties` (mẫu: `android/key.properties.example`) | Cấu hình Gradle đã sẵn; keystore + mật khẩu tự giữ, không commit | P1 |
| 0.4 | iOS Universal Links: thêm capability Associated Domains (`applinks:<host>`) trong Xcode + `IOS_APP_IDS` cho server | Custom scheme `smsnavigator://` đã có | P1 |
| 0.5 | Test thực tế ADB: cold start / mid-splash / warm start (ROADMAP_DEEPLINK_QR_V2 §6.2); 2 kênh Owner cùng khớp 1 SMS; revoke khi bật máy bay (pending key + self-heal) | | P0 |
| 0.6 | **Roadmap GĐ6 — clean-cut v4**: phát hành app mới → bật `min_version` force update → BE gỡ `pairing_token`, `invite_url` v4, `/channels/sessions/resolve`, claim bằng token → app gỡ `InvitePayload`, `LegacyInviteLink`, `JoinResolveStarted` | Thứ tự bắt buộc: không gỡ v4 trước khi force update | P1 |

---

## 1. Tính năng mới

| # | Hạng mục | Chi tiết kỹ thuật & Hướng giải quyết | Ưu tiên |
|---|---|---|---|
| 1.1 | **Export / Import Backup (khôi phục danh tính & khóa)** | Gỡ app = mất X25519 identity key → Owner mất kênh vĩnh viễn (server chỉ giữ envelope wrap bằng key đó). Export file `.smsnav` mã hóa bằng passphrase (Argon2/PBKDF2 + AES-256-GCM) chứa identity keypair, channel keys theo epoch, deviceId, deviceToken. Splash lần đầu: *"Thiết lập thiết bị mới"* / *"Khôi phục từ bản sao lưu"*. Loại QR `BACKUP` của QR v3.3 có thể dùng để chuyển máy. | P1 |
| 1.2 | **OTP hiển thị ngay trong thông báo** | Hiện thông báo chỉ "Có tin nhắn SMS mới" → member phải mở app, chọn ngày, chờ giải mã. FCM gửi data-only `{channel_id, sequence}` → app lấy ciphertext, giải mã cục bộ, hiện OTP + action **"Sao chép"**. Vẫn E2EE. Android trước (background handler); iOS cần Notification Service Extension. | P1 |
| 1.3 | FCM bell refresh màn SMS đang mở | `SmsPage` chỉ load khi khởi tạo. Wire channel event → `SmsBloc.add(SmsLoadDataEvent())`. Làm cùng 1.2. | P1 |
| 1.4 | Quản lý vòng đời kênh | Member tự rời kênh (`leave`); Owner lưu trữ / giải tán kênh (`archive`). Cần endpoint BE. | P2 |
| 1.5 | Đổi tên kênh | Owner, dialog 1–50 ký tự, `PUT /api/v2/channels/name` (BE chưa có). Cập nhật `RelayChannelStore` qua `SyncOwnerRelayChannelUseCase`. | P2 |
| 1.6 | Lịch sử yêu cầu kết nối đã xử lý (Owner) | Xem lại request `APPROVED` / `REJECTED` / `CANCELLED`. | P2 |
| 1.7 | Offline encrypted cache tin nhắn | Tin nhắn chỉ fetch online theo ngày; cân nhắc lưu local mã hóa nếu cần xem khi mất mạng. | P3 |

---

## 2. Bảo mật native (Android)

| # | Hạng mục | Chi tiết | Ưu tiên |
|---|---|---|---|
| 2.2 | Fallback lưu plaintext khi Keystore lỗi | `OtpPreferences` (device token) và `RelayChannelStore` (channel key) lưu thô nếu `SecureVault` ném lỗi. Ít nhất log/Crashlytics + cảnh báo; cân nhắc fail-closed. | P2 |

---

## 3. Nợ kỹ thuật

| # | Hạng mục | Chi tiết | Ưu tiên |
|---|---|---|---|
| 3.2 | Xử lý 401 tập trung | `ApiClient` chỉ ném `UnauthorizedException`; chưa có luồng tự đăng ký lại / báo người dùng thống nhất ngoài Splash. | P2 |
| 3.3 | **TD-3 — Tách luồng khởi động** | `SplashBloc` inject trực tiếp 7 services. Gom vào `StartupRepository.bootstrap(...)`; `SplashBloc` chỉ phụ thuộc repository. Nên làm cùng startup capability gate (3.5). | P3 |
| 3.4 | Startup reconcile N+1 | `startup_reconcile_service_impl.dart` `_provisionChannelKeys()` gọi `getChannelDetail` + `provisionLatestForApproved` từng kênh. `SyncOwnerRelayChannelUseCase` cũng gọi `getChannelDetail` mỗi kênh Owner (whitelist heal). Batch hoá. | P2 |
| 3.5 | Startup capability gate (`MaintenanceGate`, …) | Phần còn lại của roadmap startup cũ: `CapabilitySet`, `StartupGate`, `StartupCoordinator`. (Pending deeplink đã có qua `QrIngressCubit`.) | P3 |
| 3.6 | Splash phân loại lỗi bằng nội dung chuỗi | `splash_page.dart` đoán lỗi mạng bằng `msg.contains('kết nối' / 'mạng')`. Chuyển sang loại lỗi trong state (`SplashFailureKind`). | P3 |
| 3.7 | Giá trị mặc định tên thiết bị trùng l10n | `SplashStarted/SplashRetried.defaultDeviceName` và `DeviceProfileState.deviceName` còn hằng `'Thiết bị của tôi'` (bắt buộc `const`) — phải khớp `splashDefaultDeviceName`. | P3 |

---

## 4. Hạng mục đã hoàn thành (tham khảo — đừng làm lại)

- **Đợt 22/10/2026**:
  - Đã chạy `flutter analyze` (sạch), `flutter test` (271/271), `:app:testDebugUnitTest` (99/99) — cũ: mục 0.1.
  - Xác nhận Cloudflare Worker chuyển tiếp nguyên `/.well-known/*` và `/qr/*` (200, không redirect) — cũ: mục 0.3.
  - SMS relay không còn nằm plaintext trong DB WorkManager: nội dung + sender ghi mã hóa vào outbox `RelayChannelStore`, worker chỉ nhận `messageId`/`channelId`, xóa khi xong; parked queue mã hóa cả sender (cũ: mục 2.1).
  - Test hermetic (cũ: mục 3.1 / TD-4): `test/flutter_test_config.dart` chặn mọi kết nối ra ngoài loopback (kể cả qua proxy), có test bảo vệ. `testWidgets` vốn đã được `TestWidgetsFlutterBinding` trả 400 cho mọi HTTP; đo thực tế: không test `test()` nào tạo `HttpClient`.
  - Hướng dẫn chạy test (Flutter + `./gradlew :app:testDebugUnitTest` sau `flutter build apk --config-only`) trong `AGENTS.md` §8.
  - Release signing đọc `android/key.properties` (fallback debug key) + `scripts/print_android_sha256.sh`.
- **Đợt 21/10/2026** (nhánh chưa merge, xem §0):
  - Relay đa kênh: `RelayChannelStore`, mỗi SMS áp whitelist từng kênh và có worker riêng; xoay khóa stage → commit → promote, worker tự phục hồi 409 `EPOCH_OUTDATED`, SMS chờ khóa được park + gửi lại.
  - Universal Opaque QR v3.3: `QrLinkParser`, `QrIngressCubit` (pending deeplink one-shot), `QrEntryPage`, claim bằng `code`, App Links + custom scheme, nút "Dán mã" (không đọc clipboard tự động), Owner render `qr_url`.
  - Whitelist theo từng kênh + định tuyến SMS native theo kênh (cũ: mục 4.3).
  - Deeplink App Links & custom scheme (cũ: mục 4.1).
  - Gom chuỗi hardcode về `app_vi.arb`; `AppL10n.current` cho BLoC/service/FCM background.
- Kiến trúc V2 channel 1-to-N E2EE (đập bỏ V1 pairing/relay) — xem `../sms_navigator_server/SERVER_API_SPEC.md`.
- Xoá toàn bộ tàn dư V1 + dead code (`isRelayEnabled`, method channel chết, banner orphan, endpoints V1).
- FCM chuông V2: notification block cho `NEW_MESSAGE` / `JOIN_REQUEST` / `APPROVED` / `REVOKED` kèm `channel_name`.
- Auto device name từ native (`Settings.Global.DEVICE_NAME` → `bluetooth_name` → `Build` fallback) + auto-heal máy cũ (`commit d2b2a14`).
- Shimmer loading đồng bộ + pull-to-refresh phản hồi tức thì (`commit dde4e5b`, `59c3fb6`).
- Đóng gói & phân phối APK qua Firebase App Distribution (`scripts/distribute_android.sh`).

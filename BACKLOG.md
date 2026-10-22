# BACKLOG — các hạng mục chưa làm (Mobile / Flutter + Kotlin)

> Tài liệu gom toàn bộ nợ kỹ thuật + roadmap chưa triển khai của phía mobile.
> Mục đã hoàn thành bị loại khỏi danh sách; hoàn thành mục nào thì xoá mục đó.
> App chỉ hỗ trợ **Android** — không làm hạng mục iOS. Phát hành **nội bộ qua Firebase App Distribution**, không lên Google Play.
> Cập nhật lần cuối: 22/10/2026.

---

## 0. Kiểm thử & phát hành

`feat/otp-notification` đã merge `main` (mobile PR #5, BE PR #1), máy test đang chạy 1.1.0+21.
Nhánh đang mở: `fix/fast-otp-notification` (mobile: hiện thông báo chung ngay rồi thay bằng OTP — chưa compile/test; BE: chỉ backlog).

| # | Hạng mục | Ghi chú | Ưu tiên |
|---|---|---|---|
| 0.2 | Thứ tự phát hành: cài app mới lên các máy Android **rồi** mới merge BE `feat/otp-notification` vào `main` (Render tự deploy) | App cũ không hiện thông báo khi chạy nền nếu BE gửi `NEW_MESSAGE` data-only | P0 |
| 0.3b | Chuyển các máy sang keystore release: cài **1.0.1+19** (nhánh `release/1.0.1-export`, luôn ký debug key cũ → cài đè, giữ dữ liệu) → **Sao lưu** → gỡ app → cài **1.1.0 (build ≥ 20, mới nhất là +21 có icon mới)** (`main`, ký release keystore) → **Khôi phục** | Máy build bản 1.0.1 phải là máy đã build bản đang cài (cùng `~/.android/debug.keystore`), nếu không cài đè sẽ báo `INSTALL_FAILED_UPDATE_INCOMPATIBLE`. Keystore release: `./scripts/create_release_keystore.sh`, nhớ sao lưu `.jks` + `android/key.properties` | P0 |
| 0.5 | Test thực tế trên máy | Deeplink cold start / mid-splash / warm start; 2 kênh Owner cùng khớp 1 SMS; revoke khi bật máy bay (pending key + self-heal); OTP trong thông báo khi app bị vuốt tắt; **sao lưu → gỡ app → cài lại → khôi phục** (Owner relay tiếp được, Member đọc được tin cũ) | P0 |
| 0.6 | Roadmap GĐ6 — clean-cut v4: phát hành app mới → bật `min_version` force update → BE gỡ `pairing_token`, `invite_url` v4, `/channels/sessions/resolve`, claim bằng token → app gỡ `InvitePayload`, `LegacyInviteLink`, `JoinResolveStarted` | Thứ tự bắt buộc: không gỡ v4 trước khi force update | P1 |

---

## A. Lệch thiết kế & luồng chưa tối ưu (phát hiện 22/10 khi test OTP trên máy thật)

Bối cảnh: test 1.1.0+21 — tin relay tới server đúng lúc (không phải server ngủ) nhưng thông báo trên máy receiver tới rất chậm. Truy nguyên ra một chuỗi chỗ code **không làm đúng như thiết kế** hoặc làm nhiều request hơn cần thiết. Làm A8 trước để không phát hiện lẻ tẻ như lần này.

| # | Hạng mục | Chi tiết & hướng xử lý | Ưu tiên |
|---|---|---|---|
| A1 | **Đồng bộ key khi mở app chỉ lấy epoch mới nhất — lệch SRD §8.4** | SRD §8.4: client giữ key của **mọi** epoch được provision (tin 30 ngày phải giải mã được bằng key epoch cũ). Code: `StartupReconcile` → `provisionLatestForApproved` gọi `GET /channels/key-envelope` **không truyền epoch** → chỉ có key mới nhất. Member không mở app qua nhiều lần rotate (3 → 4 → 5) sẽ không bao giờ có key 4 → tin epoch 4 "không giải mã được" vĩnh viễn dù server còn envelope (BE không xoá envelope). Tối ưu 3.4 (bỏ qua kênh đã có key `current_epoch`) cũng dựa trên giả định "chỉ cần key mới nhất" → phải sửa cùng. Sửa: lấp mọi epoch thiếu trong `[my_joined_epoch, current_epoch]` qua API gom (A4). | P0 |
| A2 | **Thông báo không tự lấy key khi thiếu key của epoch tin** | Sau mỗi lần rotate (duyệt / thu hồi), BE **không báo** cho các member còn lại (A3) → tin OTP đầu tiên sau rotate tới trước lần mở app kế tiếp → thiếu key → chỉ hiện thông báo chung. Sửa: trong `NewMessageNotifier`/`ResolveIncomingMessageUseCase`, thiếu key cho `message.keyEpoch` → lấy envelope **đúng epoch của tin** (không phải "mới nhất" — tin có thể tới không theo thứ tự), unwrap, lưu, giải mã tiếp; vẫn trong timeout 10 s, thông báo chung đã hiện sẵn. Dùng API gom (A4) với `?channel_id=` → 1 request. | P0 |
| A3 | Member còn lại không được báo khi kênh rotate | Approve chỉ bắn `APPROVED` cho requester, revoke chỉ bắn `REVOKED` cho người bị thu hồi. Cân nhắc bell `KEY_ROTATED` (data-only, kèm `channel_id`, `epoch`) cho mọi member ACTIVE còn lại → app lấy key ngay (BE BACKLOG A2). Nếu đã có A1 + A2 thì đây là tối ưu, không bắt buộc. | P2 |
| A4 | API gom key envelope — bỏ N+1 | Thay `3 × số kênh` request (detail, detail lặp, envelope) bằng 1 lần `GET /api/v2/key-envelopes[?channel_id=]` trả mọi envelope của máy gọi theo kênh ACTIVE + `owner_public_key` + `current_epoch` (BE BACKLOG A1). Client bỏ qua epoch đã có key. Dùng cho A1, A2 và lần mở đầu sau khi khôi phục backup. | P0 |
| A5 | Đưa ciphertext vào FCM (chờ quyết định) | Bỏ vòng `GET /channels/message` → OTP hiện gần như ngay khi FCM tới. Vẫn E2EE (chỉ `ciphertext/nonce/key_epoch`), nhưng **phá bất biến I5** (spec §7, SRD) và Google giữ ciphertext trong TTL. Payload FCM tối đa 4 KB → tin quá dài thì bỏ ciphertext, app quay về cách cũ. Cần chủ dự án quyết bỏ I5 trước. | P2 |
| A6 | Đo & giảm độ trễ thông báo end-to-end | Đã thêm log `Placeholder shown after …ms` / `OTP shown after …ms` (nhánh `fix/fast-otp-notification`). Còn lại: (1) so mốc thời gian Render (`POST /channels/messages` → `NEW_MESSAGE bells` → `GET /channels/message`) với logcat để biết chậm ở FCM hay ở app; (2) worker relay của Owner chưa `setExpedited` → có thể bị hoãn khi Doze; (3) checklist thiết bị nên hướng dẫn **cả máy receiver** tắt tối ưu pin / bật Autostart (hiện chỉ nhấn mạnh cho Owner). | P1 |
| A7 | Hai máy chung một danh tính sau khi khôi phục | Máy cũ còn cài app sẽ ghi đè FCM token (và vẫn relay) mỗi lần mở → thông báo đi về máy mở app gần nhất. Cần cơ chế "bị thay thế": khôi phục → BE cấp `device_token` mới / tăng `token_generation`, máy cũ nhận 401 → báo "Thiết bị này đã được khôi phục trên máy khác" (liên quan 3.2). | P2 |
| A8 | **Rà soát toàn bộ luồng so với thiết kế** | Viết `docs/FLOW_AUDIT.md`: với từng luồng — relay SMS (native), tạo kênh, mời/claim/duyệt/từ chối, thu hồi + rotate, đồng bộ khi mở app, thông báo (foreground/background), màn SMS theo ngày, whitelist, deeplink/QR, sao lưu/khôi phục — ghi **hành vi thực tế đọc từ code** (request nào, theo thứ tự nào, lỗi thì sao) rồi đối chiếu bất biến trong SRD/spec (I*, KL*, N*, T*). Mỗi chỗ lệch → một mục backlog + test hợp đồng giữ đúng hành vi. Kèm số request mỗi luồng để tìm N+1 còn sót. | P0 |

---

## 1. Tính năng mới

| # | Hạng mục | Chi tiết kỹ thuật & Hướng giải quyết | Ưu tiên |
|---|---|---|---|
| 1.4 | Quản lý vòng đời kênh | Member tự rời kênh (`leave`); Owner lưu trữ / giải tán kênh (`archive`). Cần endpoint BE (BE BACKLOG 2.2). | P2 |
| 1.5 | Đổi tên kênh | Owner, dialog 1–50 ký tự, `PUT /api/v2/channels/name` (BE BACKLOG 2.1, chưa có). Cập nhật `RelayChannelStore` qua `SyncOwnerRelayChannelUseCase`. | P2 |
| 1.6 | Lịch sử yêu cầu kết nối đã xử lý (Owner) | Xem lại request `APPROVED` / `REJECTED` / `CANCELLED`. | P2 |
| 1.7 | Offline encrypted cache tin nhắn | Tin nhắn chỉ fetch online theo ngày; cân nhắc lưu local mã hóa nếu cần xem khi mất mạng. | P3 |
| 1.8 | Bỏ thông báo cho chính máy relay có thể cấu hình | 1.2 bỏ qua `NEW_MESSAGE` do chính máy gửi (Owner đã có SMS gốc). Nếu cần: thêm tuỳ chọn bật lại. | P3 |
| 1.9 | Nhắc tạo bản sao lưu | Owner chưa từng sao lưu (hoặc vừa tạo/tham gia kênh mới sau lần sao lưu cuối) → banner nhắc. Bản sao lưu cũ không chứa key của các epoch sau đó; danh tính vẫn khôi phục được nhưng **hiện tại chỉ lấy lại được key epoch mới nhất** (xem A1). | P2 |

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
| 3.8 | **`distribute.yml` ký APK sai key** | Workflow chạy khi push tag `v*` / bấm tay: runner không có `android/key.properties` → ký bằng debug key **mới sinh mỗi lần chạy** → APK không cài đè được lên 1.1.0 (khác chữ ký) và App Links mất `verified`. Trước khi dùng lại: thêm secret `ANDROID_KEYSTORE_BASE64` + mật khẩu, bước giải mã ra `.jks` và ghi `key.properties`, rồi kiểm tra chữ ký bằng `scripts/print_android_sha256.sh` (phải ✅). Tới lúc đó: **chỉ phát hành bằng `scripts/distribute_android.sh` trên máy build** | P1 |
| 3.9 | CI cho pull request | Chưa có workflow chạy khi mở PR (chỉ có `distribute.yml`). Thêm job `pull_request`: `flutter analyze`, `flutter test`, `flutter build apk --config-only` + `cd android && ./gradlew :app:testDebugUnitTest`. Ghim cùng Flutter với máy dev (`distribute.yml` đang ghim 3.47.5). Lý do: đợt 22/10 có code chưa từng compile nằm trên nhánh và một widget test hỏng | P1 |
| 3.10 | Nâng Gradle / AGP / Kotlin | Flutter cảnh báo sắp ngừng hỗ trợ Gradle 8.14, AGP 8.11.1, Kotlin 2.2.20 → cần Gradle ≥ 9.1, AGP ≥ 9.0.1, Kotlin ≥ 2.3.20. Nâng trên nhánh riêng, chạy đủ test + build APK release và kiểm tra chữ ký không đổi | P3 |

---

## 4. Hạng mục đã hoàn thành (tham khảo — đừng làm lại)

- **Nhánh `fix/fast-otp-notification`** (chưa merge, chưa compile): isolate nền hiện **ngay** thông báo chung khi nhận `NEW_MESSAGE` data-only rồi thay bằng OTP (cùng id, `onlyAlertOnce`); timeout request nền 10 s; Firebase chỉ khởi tạo khi cần ghi Crashlytics; log thời gian.
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

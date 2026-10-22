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

---

## A. Lệch thiết kế & luồng chưa tối ưu (phát hiện 22/10 khi test OTP trên máy thật)

Kết quả rà soát đầy đủ: `docs/FLOW_AUDIT.md`. Bối cảnh: test 1.1.0+21 — tin relay tới server đúng lúc (không phải server ngủ) nhưng thông báo trên máy receiver tới rất chậm. Truy nguyên ra một chuỗi chỗ code **không làm đúng như thiết kế** hoặc làm nhiều request hơn cần thiết. Làm A8 trước để không phát hiện lẻ tẻ như lần này.

| # | Hạng mục | Chi tiết & hướng xử lý | Ưu tiên |
|---|---|---|---|
| A3 | Member còn lại không được báo khi kênh rotate | Approve chỉ bắn `APPROVED` cho requester, revoke chỉ bắn `REVOKED` cho người bị thu hồi. Cân nhắc bell `KEY_ROTATED` (data-only, kèm `channel_id`, `epoch`) cho mọi member ACTIVE còn lại → app lấy key ngay (BE BACKLOG A2). Nếu đã có A1 + A2 thì đây là tối ưu, không bắt buộc. | P2 |
| A5 | Đưa ciphertext vào FCM (chờ quyết định) | Bỏ vòng `GET /channels/message` → OTP hiện gần như ngay khi FCM tới. Vẫn E2EE (chỉ `ciphertext/nonce/key_epoch`), nhưng **phá bất biến I5** (spec §7, SRD) và Google giữ ciphertext trong TTL. Payload FCM tối đa 4 KB → tin quá dài thì bỏ ciphertext, app quay về cách cũ. Cần chủ dự án quyết bỏ I5 trước. | P2 |
| A6 | Đo & giảm độ trễ thông báo end-to-end | Đã thêm log `Placeholder shown after …ms` / `OTP shown after …ms` (nhánh `fix/fast-otp-notification`). Còn lại: (1) so mốc thời gian Render (`POST /channels/messages` → `NEW_MESSAGE bells` → `GET /channels/message`) với logcat để biết chậm ở FCM hay ở app; (2) worker relay của Owner chưa `setExpedited` → có thể bị hoãn khi Doze; (3) checklist thiết bị nên hướng dẫn **cả máy receiver** tắt tối ưu pin / bật Autostart (hiện chỉ nhấn mạnh cho Owner). | P1 |
| A7 | Hai máy chung một danh tính sau khi khôi phục | Máy cũ còn cài app sẽ ghi đè FCM token (và vẫn relay) mỗi lần mở → thông báo đi về máy mở app gần nhất. Cần cơ chế "bị thay thế": khôi phục → BE cấp `device_token` mới / tăng `token_generation`, máy cũ nhận 401 → báo "Thiết bị này đã được khôi phục trên máy khác" (liên quan 3.2). | P2 |
| A8 | ~~Rà soát toàn bộ luồng so với thiết kế~~ | **Xong** — xem `docs/FLOW_AUDIT.md`. Phát hiện mới ghi thành A9–A15 dưới đây; lỗi C1 (thông báo luôn rơi về nội dung chung do AAD lệch sequence) đã sửa trên `fix/fast-otp-notification`. | — |
| A10 | KL10 không được thực thi (C2) | AAD tin nhắn luôn `seq = 0` vì Owner mã hoá trước khi server cấp sequence → server có thể nhân bản / gán lại ciphertext cũ. Đề xuất: bộ đếm `client_seq` phía Owner (native, lưu trong `RelayChannelStore`) đưa vào AAD `sms-navigator-msg-v2`; giải mã cả v1 cho tin cũ. Cần quyết định thiết kế (FLOW_AUDIT §5) + sửa SRD §7.1. | P1 |
| A13 | Key material chưa được dọn (R1, R2) | (1) Bị thu hồi (`REVOKED` / 403) → gọi `purgeChannelKeys` (hiện không ai gọi) + bỏ kênh khỏi native relay, đúng bảng lỗi spec §2. (2) Rotate bị từ chối 4xx → xoá cả key epoch N+1 trong key store Dart (cần `deleteChannelKey(channelId, epoch)`), không chỉ native. | P1 |
| A14 | Tạo kênh không idempotent (C3) | Mất mạng sau khi server đã tạo → thử lại sinh UUID mới → kênh trùng. Giữ nguyên `channel_id` + key cho lần thử lại; server trả `409 CHANNEL_ID_TAKEN` → coi như đã tạo (kiểm `GET /channels`). | P2 |
| A15 | Chuông `JOIN_REQUEST` không làm mới màn duyệt của Owner (U2) | `ChannelEvent.affectsMessages` chỉ phục vụ màn SMS; thêm luồng sự kiện cho màn chi tiết kênh / danh sách yêu cầu. | P3 |

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

- **PR #3 `feat/backlog-sweep`** — sửa theo rà soát A8 (`docs/FLOW_AUDIT.md`):
  - **S1 / A9** — không còn đăng ký lại cùng `device_id` sau 401: `registerDevice` luôn sinh `device_id` mới; Splash gặp 401 → bỏ token, đưa về lựa chọn "Khôi phục / Thiết lập mới"; `DeviceSessionRecovery` chỉ báo người dùng, không gọi server. Đi cùng BE A7 (409 `DEVICE_EXISTS`).
  - **A1 / A2 / A4 / A11** — `SyncChannelKeysUseCase` + `GET /key-envelopes`: giữ key **mọi** epoch (SRD §8.4) bằng 1 request; thông báo thiếu key của epoch tin → lấy ngay rồi giải mã; màn SMS gặp tin thiếu key → đồng bộ 1 lần rồi giải mã lại (phủ "được duyệt khi đang mở app"); epoch trước lúc tham gia được nhớ để không gọi lại.
  - **A12** — reconcile single-flight + 30 s, không còn lấy lại key cho mọi request APPROVED; sync relay single-flight + 10 s, dùng `whitelist` + `rotation_pending` từ `GET /channels` (không đọc detail từng kênh), thiếu key Owner → key sync 1 request.
- **Nhánh `fix/fast-otp-notification`** (đã gộp vào PR #3): sửa **C1** — thông báo giải mã với `sequenceHint = 0` như Owner mã hoá (trước đó truyền `sequence_number` thật → AAD lệch → mọi thông báo rơi về nội dung chung); rà soát A8 → `docs/FLOW_AUDIT.md`; isolate nền hiện **ngay** thông báo chung khi nhận `NEW_MESSAGE` data-only rồi thay bằng OTP (cùng id, `onlyAlertOnce`); timeout request nền 10 s; Firebase chỉ khởi tạo khi cần ghi Crashlytics; log thời gian.
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
- Đóng gói & phân phối APK qua Firebase App Distribution (`scripts/distribute.sh`).

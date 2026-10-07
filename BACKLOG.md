# BACKLOG — các hạng mục chưa làm (Mobile / Flutter + Kotlin)

> Tài liệu gom toàn bộ nợ kỹ thuật + roadmap chưa triển khai của phía mobile.
> Mục đã hoàn thành bị loại khỏi danh sách; hoàn thành mục nào thì xoá mục đó.
> Cập nhật lần cuối: 07/10/2026.

---

## 1. QR đa năng + Startup Gate (roadmap — chưa triển khai)

### Trạng thái đã xong (đừng làm lại)
- In-app scanner + quét QR từ ảnh Gallery; deeplink ingress GĐ3.
- Lộ trình bảo mật QR **GĐ0–GĐ4 hoàn tất** (ECDH, TTL 10 phút, one-time 409).
- Xoá tàn dư V1 (pair/relay) khỏi app.

### Bước 1 — Tách điểm entry khỏi nghiệp vụ (chi phí thấp, đáng làm nhất)
- Trên nền `qr_scan_page.dart`: thêm `QrParser` (URL-first, legacy-JSON fallback) + `QrHandlerRegistry`.
- Handler đầu tiên: `PairingHandler` bọc luồng `PairingSubmitReceiverQrEvent` hiện có.
- Không đụng BE. Scanner không còn biết gì về pairing.

### Bước 2 — Dựng khung startup capability-based
- `lib/core/startup/`: `CapabilitySet`, `StartupGate`, `StartupCoordinator`, `StartupBloc`, `PendingIntentStore`.
- Gate đầu tiên: `MaintenanceGate` (+ `AuthenticationGate` nếu có auth).
- Root app: `BlocListener<StartupBloc>` điều khiển màn blocker / ready.

**Hợp đồng thiết kế cốt lõi (giữ nguyên khi implement):**
- QR = URL opaque `https://<domain-đã-verify>/qr/v1/{key}`; BE resolve (`GET /qr/v1/{key}`) là source of truth; client chỉ parse cấu trúc URL.
- `PendingIntentStore`: single-slot (latest wins), one-shot `consume()`, chỉ IntentRouter (sau `StartupReady`) được consume; EntryHandler chỉ save, không navigate.
- Startup = vòng lặp capability fixpoint: gate khai báo `requires` theo **capability** (không theo gate khác); **"Gate detect, flow emit"** — gate chỉ trả `blocked(blockerId)`, fact mới do flow emit `StartupCapabilityAdded`.
- Gate tương tác **không await UI** trong `evaluate()`; gate runtime check khai báo `requiresFreshCheck: true`.
- Capability set **append-only** trong suốt startup; revoke/runtime concern không đưa vào startup model.
- Priority chỉ là tie-breaker: field `order` cho thứ tự evaluate + chọn blocker hiển thị khi nhiều gate block cùng lúc.
- Fixpoint driver dùng `droppable()` chống re-entrancy.

### Bước 3 — Migrate QR sang URL opaque (phối hợp BE, xem BACKLOG của server)
- Client: `PairingRepository` đổi sang resolve-based flow; **dọn shared secret khỏi QR** (`PairingPayloadModel.toQrData()` hiện còn nhúng secret) — chuyển sang exchange sau resolve.
- Cấu hình App Links: `assetlinks.json` + intent filter `AndroidManifest.xml` (Universal Links/AASA nếu hỗ trợ iOS sau này).
- Tương thích ngược: `QrParser.parse()` 3 nhánh — URL mới → resolve; legacy JSON → luồng cũ; khác → toast lỗi. Sau 1 release bỏ nhánh legacy.

### Câu hỏi cần chốt trước khi làm
1. Domain verify cho App Links (blocker hạ tầng Bước 3 — ảnh hưởng cả BE).
2. Độ dài key: khuyến nghị 22 ký tự base64url ≈ 128-bit.
3. Policy resolve fail: khuyến nghị retry inline cho 5xx, terminal cho 403/409/410.
4. Giai đoạn tương thích QR legacy JSON: khuyến nghị 1 release (TTL QR chỉ 10 phút).

---

## 2. TD-3 — Nợ kiến trúc phân tầng luồng khởi động (P3)

- **Vấn đề**: `SplashBloc` inject trực tiếp 7 services (`CrashlyticsService`, `AnalyticsService`, `FcmNotificationService`, `DeviceStorageService`, `ChannelKeyStore`, `DeviceApiService`, `StartupReconcileService`) và điều phối 7 bước bootstrap trong BLoC; `SplashPage` đọc services từ Context để build BLoC.
- **Tác động**: coupling cao, test setup dài (mock 7 service/test), thêm service mới phải sửa cả BLoC lẫn Page.
- **Hướng xử lý**:
  1. Xây `StartupRepository` (hoặc `BootstrapUseCase`): gom 7 bước vào `bootstrap({required String defaultDeviceName, CancelToken? cancelToken})`, chịu error mapping + observability. `SplashBloc` chỉ inject duy nhất repository này.
  2. DI tại root (`main.dart`): khởi tạo `StartupRepository` + `SplashBloc` từ root, `SplashPage` thuần lắng nghe state.
- Ghi chú: khi làm Bước 2 (startup gate), nên gộp refactor này vào cùng đợt.

---

## 3. TD-4 — Widget test gọi HTTP thật tới Production Server (P2)

- **Vấn đề**: widget test tích hợp (`widget_test.dart`, `MainNavigationPage`) mount cây khiến `SmsBloc`/`ChannelBloc` tự gọi `ApiClient` với baseUrl production (`https://sms-navigator-server.onrender.com`); log nhiễm `[API ERR] ... manually cancelled`, test phụ thuộc mạng + Render state.
- **Hướng xử lý**:
  1. `flutter_test_config.dart` toàn cục: `HttpOverrides.global` chặn mọi socket ngoài loopback khi test.
  2. Test tích hợp lớn inject mock `ApiClient`/fake repository thay vì dùng production default.
- Mục tiêu: CI hermetic, chạy offline hoàn toàn.

---

## 4. Các tính năng & nợ kỹ thuật tồn đọng (Roadmap P2 & Refactoring)

| # | Hạng mục | Chi tiết | Ưu tiên |
|---|---|---|---|
| 4.1 | FCM bell không refresh màn SMS đang mở | `SmsPage` chỉ load khi khởi tạo (`sms_page.dart`); không có wiring bell → `SmsBloc`. Wire channel event → `add(SmsLoadDataEvent())` để danh sách tự cập nhật realtime khi đang mở app | P1 |
| 4.2 | Startup reconcile N+1 | `startup_reconcile_service_impl.dart` `_provisionChannelKeys()`: mỗi channel gọi riêng `getChannelDetail` + `provisionLatestForApproved` — batch hoá hoặc giới hạn scope | P2 |
| 4.3 | Lịch sử yêu cầu kết nối đã xử lý (Owner) | Màn hình/tab xem lại các yêu cầu ghép đôi đã duyệt (`APPROVED`), từ chối (`REJECTED`) hoặc bị hủy (`CANCELLED`) (chuyển tiếp từ `MOBILE_FEATURES.md` mục 4.5) | P2 |
| 4.4 | Quản lý vòng đời thành viên kênh (Member & Owner) | Member có tùy chọn tự rời kênh (`leave channel`); Owner có tùy chọn giải tán hoặc lưu trữ kênh (`archive channel`) (chuyển tiếp từ `MOBILE_FEATURES.md` mục 7.3) | P2 |
| 4.5 | Offline Encrypted Cache tin nhắn (tuỳ chọn) | Hiện tại tin nhắn chỉ fetch online theo ngày từ server; cân nhắc mã hóa lưu trữ local (drift/hive) nếu cần xem lại tin nhắn khi mất mạng | P3 |

---

## 5. Hạng mục đã hoàn thành (tham khảo — đừng làm lại)

- Kiến trúc V2 channel 1-to-N E2EE (đập bỏ V1 pairing/relay) — xem `../sms_navigator_server/SERVER_API_SPEC.md`.
- Xoá toàn bộ tàn dư V1 + dead code (`isRelayEnabled`, method channel chết, banner orphan, endpoints V1).
- FCM chuông V2: notification block đầy đủ cho `NEW_MESSAGE` / `JOIN_REQUEST` / `APPROVED` / `REVOKED` kèm `channel_name`.
- Auto device name từ native (`Settings.Global.DEVICE_NAME` → `bluetooth_name` → `Build` fallback) + auto-heal máy cũ (`commit d2b2a14`).
- Tối ưu UI Shimmer loading đồng bộ trên tất cả danh sách và phản hồi tức thì khi kéo pull-to-refresh (`commit dde4e5b`, `59c3fb6`).
- Tự động đóng gói và phân phối release APK qua Firebase App Distribution (`scripts/distribute_android.sh`).

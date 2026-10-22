# Rà soát luồng so với thiết kế (BACKLOG A8)

> Ngày 22/10/2026. Đọc code — **không** chạy trên máy thật.
> Mobile: `main` @ `bc81e47` (+ nhánh `fix/fast-otp-notification`). BE: `main` @ `c826519`.
> Đối chiếu với `SRD_DATABASE.md` (N1–N8, KL1–KL12, §4 T0–T6, §7, §8) và `SERVER_API_SPEC.md` (I5, bảng lỗi §2).
> Mỗi phát hiện có mã (`S`, `C`, `K`, `P`, `R`, `D`, `B`, `U`) và trỏ sang mục backlog tương ứng.

---

## 1. Tóm tắt

| Mức | Mã | Phát hiện | Trạng thái |
|---|---|---|---|
| **P0** | **S1** | **Chiếm quyền thiết bị**: `POST /devices/register` không cần xác thực, nhận `device_id` đã tồn tại → ghi đè `token_hash` **và** `public_key`. `device_id` không bí mật (danh sách thành viên, `sender_device_id`). Thành viên bất kỳ chiếm được máy Owner → duyệt/thu hồi, cài public key của mình để nhận khoá các epoch sau | **Đã sửa** — BE PR #2, mobile PR #3 |
| **P0** | C1 | Thông báo luôn rơi về nội dung chung: giải mã với AAD chứa `sequence_number` thật, trong khi Owner mã hoá với `0` | **Đã sửa** (`dbbddd3`, nhánh `fix/fast-otp-notification`) |
| **P0** | K1 | Mở app chỉ lấy key epoch **mới nhất** — lệch SRD §8.4 | **Đã sửa** — `GET /key-envelopes` + `SyncChannelKeysUseCase` |
| **P0** | K2 | Thông báo không tự lấy key khi thiếu key của epoch tin | **Đã sửa** — thông báo tự lấy key đúng epoch |
| P1 | C2 | **KL10 không được thực thi**: AAD của tin luôn có `seq = 0` → server có thể gán lại / phát lại ciphertext cũ với sequence khác mà client không phát hiện | Cần quyết định thiết kế — mobile A10, BE A8 |
| P1 | K3 | Member được duyệt khi đang mở app: không lấy key cho tới lần reconcile sau → màn SMS hiện "không giải mã được" | **Đã sửa** — màn SMS gặp tin thiếu key → đồng bộ key rồi giải mã lại |
| P1 | P1 | Mỗi lần mở app ≈ **25–35 request** (reconcile chạy 3 lần, sync relay 2 lần, `GET /channels` ~6 lần) — tối thiểu cần ~5 | **Đã sửa** — reconcile / sync relay single-flight, không đọc detail từng kênh |
| P1 | P2 | Mỗi lần app quay lại foreground: `GET /channels/detail` cho **từng** kênh Owner (chỉ để lấy whitelist) | **Đã sửa** — reconcile / sync relay single-flight, không đọc detail từng kênh |
| P1 | R1 | Bị thu hồi **không xoá** key của kênh (spec §2 yêu cầu purge) — `purgeChannelKeys` không có nơi gọi | Mobile A13 |
| P1 | U1 | Worker relay của Owner không `setExpedited` → có thể bị hoãn khi Doze | Mobile A6 |
| P2 | D1 | SRD §8.2 ("cài lại = danh tính mới, phải join lại") trái với sao lưu/khôi phục 1.1 | Sửa SRD — mobile A7 |
| P2 | R2 | Rotate bị từ chối (4xx): native bỏ key pending nhưng **key store Dart vẫn giữ** key chưa commit (lọt cả vào bản sao lưu) | Mobile A13 |
| P2 | C3 | Tạo kênh không idempotent: mất mạng sau khi server đã tạo → người dùng thử lại → kênh trùng (mỗi lần UUID mới) | Mobile A14 |
| P2 | B1 | Không có job dọn nào: tin nhắn (retention 30 ngày **không được thực thi** — `server_received_at` là chuỗi ISO, không dùng được Firestore TTL), pairing session/request, envelope | BE A4, A9 |
| P3 | U2 | Chuông `JOIN_REQUEST` không làm mới danh sách yêu cầu chờ duyệt của Owner khi app đang mở | Mobile A15 |

Đã kiểm và **đúng thiết kế**: KL2, KL3/KL4 (BE kiểm package), KL5, KL6, KL7 (+ tự phục hồi 409 ở native), KL8, KL9, KL11, KL12 (server lọc theo membership), N1, N2, N4, N6 (phía server), N7, N8, I5, T5 (phòng thủ bổ sung).

---

## 2. Bảng bất biến

| Bất biến | Kết quả | Bằng chứng |
|---|---|---|
| N1 server mù | ✅ | Server chỉ lưu ciphertext + envelope; không có code sinh/giải key |
| N3 chưa duyệt chưa có key | ✅ | Envelope chỉ tạo trong T0/T2/T4 |
| N5 QR single-use + TTL 10' | ⚠️ | Hết hạn được kiểm khi claim (an toàn); **không có** TTL index / job dọn → session tồn tại mãi (B1) |
| N6 sequence là nguồn đồng bộ | ✅ server / ⚠️ client | Server cấp sequence trong transaction; nhưng ciphertext không gắn sequence (C2) |
| N8 FCM không là nguồn sự thật | ✅ | Mất FCM chỉ mất chuông; màn SMS tải theo ngày, tải lại khi foreground (1.3) |
| I5 FCM chỉ là chuông | ✅ | `NEW_MESSAGE` chỉ có metadata (A5 nếu đổi phải sửa spec) |
| KL1 | ✅ | — |
| KL2 Owner là authority | ✅ *nhưng* bị S1 vô hiệu: ai chiếm được máy Owner thì là "Owner" |
| KL3/KL4 envelope cho mọi ACTIVE + Owner | ✅ | BE kiểm package → `422 PACKAGE_INCOMPLETE`; client bỏ qua member có `public_key` rỗng → sẽ bị 422 (đúng) |
| KL6 base_epoch/version | ✅ | Package dựng 1 lần, retry gửi y hệt; BE `last_rotation` → `replayed` |
| KL7 | ✅ | T3 + native tự promote key staged khi 409 `EPOCH_OUTDATED` |
| KL8 | ✅ server | T4 envelope set đúng; `GET key-envelope` → 403 REVOKED |
| KL9 envelope AAD | ✅ | `bind(ch, epoch, device)` cả Dart/Kotlin/BE không giải |
| **KL10 message AAD gắn sequence** | ❌ | `OtpRelayWorker` mã hoá với `sequenceHint = 0L` (Owner chưa biết sequence) → AAD = `bind(ch, epoch, 0)` cho mọi tin (C2) |
| KL11 | ✅ | T0/T2/T4 đều sinh key mới; T3 không đổi epoch |
| KL12 | ✅ server / ⚠️ client | Server chặn đúng; client không purge key khi bị thu hồi (R1) |
| SRD §8.4 giữ key mọi epoch | ❌ | Client chỉ lấy epoch mới nhất (K1) |
| SRD §8.2 reinstall | ⚠️ | Mâu thuẫn với 1.1 (D1); và 401 → app **đăng ký lại cùng `device_id`** — chỉ chạy được nhờ lỗ hổng S1 |

---

## 3. Từng luồng

Ký hiệu: `→` request HTTP; *(native)* = Kotlin; số trong `[ ]` = số request.

### F1. Relay SMS (máy Owner, native)

1. `SmsReceiver`: đọc kênh từ `RelayChannelStore`; với **từng** kênh: whitelist → khử trùng TTL → `RelayWorkScheduler.enqueue` (text + sender vào outbox mã hoá — 2.1).
2. `OtpRelayWorker` (WorkManager, ràng buộc có mạng, **không expedited** — U1): đọc key `activeEpoch` lúc chạy → mã hoá AES-GCM, AAD `bind(ch, epoch, 0)` (C2) → `POST /channels/messages` [1].
3. 409 `EPOCH_OUTDATED` → có key staged cho `current_epoch` thì promote + gửi lại [+1]; không có → park, chờ app mở (`flushParkedMessages`). 409 `REPLAY_DETECTED` → coi là thành công. 5xx/mạng → retry (tối đa 5).
4. Server T5 → T3 → tăng `sequence_counter` → lưu → `notifyNewMessage` (F6).

Đúng thiết kế, trừ C2 và U1.

### F2. Tạo kênh (T0)

`createChannel`: sinh UUID + CK₁ → self-envelope → `POST /channels` [1] → **sau khi server trả về** mới lưu key vào key store. App bị kill giữa chừng → kênh có trên server, máy chưa có key → `SyncOwnerRelayChannel` tự phục hồi bằng self-envelope (KL4) ✅. Mất mạng sau khi server đã tạo → người dùng thử lại với UUID mới → kênh trùng (C3; server đã có `409 CHANNEL_ID_TAKEN`, chỉ cần client giữ nguyên UUID khi thử lại).

### F3. Mời → claim → duyệt (T1, T2)

- Owner: `POST /channels/sessions` [1] → QR `qr_url`.
- Member: `GET /qr/resolve` [1] → `POST /pairing/requests {code}` [1] (T1) → chờ.
- Owner duyệt: `GET /channels/detail` + `GET /channels/members` [2] → dựng package (envelope cho Owner + mọi ACTIVE + requester, epoch N+1) → lưu key Dart + stage native → `POST /pairing/requests/approve` [1, retry y hệt khi mất mạng] → promote native → mã hoá lại whitelist ở epoch mới → `PUT /channels/whitelist` [1].
- Chuông: chỉ `APPROVED` → requester. **Member cũ không được báo** (mobile A3 / BE A2).
- Requester nhận `APPROVED`: app chỉ làm mới màn SMS, **không** lấy key (K3). Key chỉ đến khi reconcile chạy lại (mở tab Kênh / mở lại app) → trong lúc đó tin của kênh mới hiện "không giải mã được".

### F4. Thu hồi + rotate (T4)

Giống duyệt: [2] snapshot → package `{Owner} ∪ ACTIVE còn lại` → `POST /channels/revoke` [1] → whitelist [1]. Chuông `REVOKED` → máy bị thu hồi. Máy đó: server chặn đúng (403 / lọc khỏi `GET /messages`), nhưng app **không xoá** key của kênh (R1). Rotate bị từ chối 4xx → native discard, Dart vẫn giữ key epoch N+1 chưa commit (R2; vô hại cho tới khi epoch N+1 được commit với key khác — `saveChannelKey` ghi đè — nhưng lọt vào bản sao lưu).

### F5. Mở app (Splash → màn chính)

Chạy theo thứ tự trong code (máy đã đăng ký, `O` kênh Owner, `M` kênh Member, `R` request đã APPROVED trong lịch sử):

| Bước | Request |
|---|---|
| Splash: `GET /devices/me` | 1 |
| Splash: `PUT /devices/fcm-token` | 1 |
| Splash: `StartupReconcile` — `GET /pairing/requests/mine` + với **mỗi** request APPROVED (kể cả từ nhiều tháng trước): `GET /channels/detail` + `GET /channels/key-envelope` | 1 + 2R |
| Splash: reconcile — `GET /channels` + 2 cho mỗi kênh thiếu key `current_epoch` | 1 (+2/kênh thiếu) |
| `app.dart`: sync relay khởi động — `GET /channels` + `GET /channels/detail` mỗi kênh Owner | 1 + O |
| `MainNavigationPage`: reconcile **lần 2** | 2 + 2R |
| Tab Kênh (IndexedStack dựng sẵn): `GET /channels` + `GET /pairing/requests/mine` | 2 |
| Tab Kênh: reconcile **lần 3** (nếu lần 2 đã xong) + sync relay **lần 2** | 2 + 2R + 1 + O |
| Tab SMS: `GET /messages?date=` | 1 |

Ví dụ `O = 2, R = 2` → khoảng **28 request** mỗi lần mở app. Cần tối thiểu: `devices/me`, `fcm-token`, `channels`, `key-envelopes` (BE A1), `messages` = **5** (P1). Thêm: mỗi lần quay lại foreground, `AppLifecycleObserver` chạy sync relay → `1 + O` request (P2).

### F6. Thông báo tin mới

- Server: `listActiveMembers` + đọc device từng member (song song) → Android: data-only; khác: kèm notification block; log `sent/failed/no_token`.
- App đang mở: phát sự kiện → màn SMS tải lại ngầm; `NewMessageNotifier`: bỏ qua nếu tin do chính máy gửi → `GET /channels/message` [1] → giải mã → OTP.
- App ở nền: `firebaseMessagingBackgroundHandler` → (nhánh fix) hiện ngay thông báo chung → `GET /channels/message` [1, timeout 10 s] → giải mã → thay bằng OTP.
- Lỗi: C1 (đã sửa) khiến **mọi** lần giải mã thất bại; K2 khi thiếu key epoch; tin tới không theo thứ tự không ảnh hưởng (key chọn theo `key_epoch` của tin, id thông báo theo `(kênh, sequence)`).

### F7. Màn SMS theo ngày

`GET /messages?date&tz_offset` [1] → mỗi `(kênh, epoch)` đọc key 1 lần → giải mã theo lô (≥ 16 tin chạy isolate). Thiếu key → "không giải mã được", **không** kích hoạt lấy key (nên làm cùng K1/K2: thấy tin thiếu key thì gọi `key-envelopes` rồi giải mã lại).

### F8. Whitelist

Owner sửa → `PUT /channels/whitelist` (mã hoá ở epoch hiện tại, optimistic version) + ghi native. Sau rotate mã hoá lại; gián đoạn thì sync relay tự chữa. Đồng bộ xuống native: mỗi lần sync relay đọc `GET /channels/detail` từng kênh Owner (P2) — có thể bỏ nếu `GET /channels` trả `whitelist_version` để chỉ đọc detail khi version đổi.

### F9. QR / deeplink

Một cổng `QrIngressCubit` cho camera / dán mã / App Links / custom scheme; preview `GET /qr/resolve` không lộ `session_id`/token; claim bằng `code`. Không thấy lệch.

### F10. Đăng ký thiết bị & token

- Lần đầu: `POST /devices/register {device_id (client sinh), public_key, …}` → token.
- 401 khi mở app: xoá token → **đăng ký lại với `device_id` cũ** → server cấp token mới và ghi đè `public_key`. Chính đường này cho phép S1: server không đòi bằng chứng sở hữu `device_id`.
- FCM token: `PUT /devices/fcm-token` mỗi lần mở app + khi Firebase đổi token.

### F11. Sao lưu / khôi phục (1.1)

Đúng thứ tự an toàn (device token ghi sau cùng). Lệch tài liệu: SRD §8.2 (D1). Hai máy chung danh tính (A7). Bản sao lưu cũ thiếu key các epoch sau đó → cần K1 để tự bù.

---

## 4. S1 chi tiết (ưu tiên cao nhất)

**Kịch bản:** member M của kênh K đọc `device_id` của Owner O từ `GET /channels/members` → `POST /api/v2/devices/register {device_id: O, public_key: <của M>, …}` (không cần token) → server ghi đè token và public key của O → M cầm token của O:

- gọi `approve` / `revoke` như Owner (KL2 chỉ so `owner_device_id == caller`) → tự thêm máy khác, thu hồi người khác, xoay khoá;
- mọi package sau đó (do máy O thật hay M tạo) đều wrap key cho `public_key` mà server đang giữ — tức key của M;
- máy O thật nhận 401 → app tự "đăng ký lại" cùng `device_id` → hai bên giành nhau token.

**Hướng sửa (cần làm trước khi mở rộng người dùng):**

1. BE: `POST /devices/register` với `device_id` **đã tồn tại** → `409 DEVICE_EXISTS`, trừ khi request kèm token hợp lệ của chính thiết bị đó (khi đó chỉ được xoay token, **không** đổi `public_key`).
2. Mobile: 401 không còn tự đăng ký lại cùng `device_id`. Hai lựa chọn cho người dùng: khôi phục từ bản sao lưu (giữ danh tính), hoặc thiết lập như máy mới (`device_id` + danh tính mới, join lại — đúng SRD §8.2). Gộp với 3.2 (xử lý 401 tập trung).
3. (Tuỳ chọn) Chứng minh sở hữu danh tính khi cần cấp lại token: server gửi challenge, client trả MAC bằng `ECDH(sk_device, pk_server)` — làm được với X25519, không cần khoá ký riêng.

---

## 5. C2 / KL10 — lựa chọn thiết kế

Owner mã hoá **trước** khi server cấp sequence, nên không thể đưa sequence thật vào AAD như SRD §7.1 viết. Hệ quả: server (hoặc ai ghi được Firestore) có thể nhân bản / đổi thứ tự / gán lại ciphertext cũ sang sequence khác mà client vẫn giải mã được. T5 (in-memory, 24 h) chỉ là phòng thủ bổ sung, không thay được.

Lựa chọn:

- **a. Bộ đếm phía Owner:** native giữ `client_seq` tăng dần mỗi kênh, đưa vào AAD và gửi kèm; server lưu; client kiểm `client_seq` không lặp trong cùng `(kênh, epoch)`. Cần lưu bộ đếm bền (đã có `RelayChannelStore`).
- **b. Gắn `message_id` do Owner sinh** (UUID) vào AAD và để server dùng nó làm id: chống gán lại nội dung giữa các tin, không chống xoá/đổi thứ tự.
- **c. Chấp nhận và sửa SRD:** ghi rõ KL10 chỉ còn ở mức "server không đổi được epoch/kênh"; mô hình đe doạ không coi server là kẻ phá rối thứ tự.

Đề xuất: **a** (đổi định dạng AAD → cần version mới `sms-navigator-msg-v2`, giải mã cả v1 cho tin cũ).

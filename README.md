# SMS Navigator

Ứng dụng Flutter chuyển tiếp tin nhắn SMS (OTP) từ một điện thoại cắm SIM sang nhiều thiết bị khác, **mã hóa đầu-cuối (E2EE)** — server chỉ chuyển tiếp ciphertext và không bao giờ đọc được nội dung.

Backend đi kèm: [sms_navigator_server](https://github.com/vubaochau-coder/sms_navigator_server).

---

## 1. Cách hoạt động

- **Kênh 1-to-N:** Máy cắm SIM là **Chủ kênh (Owner)**. Owner tạo kênh, các máy khác (**Thành viên**) quét mã QR để xin tham gia, Owner duyệt hoặc từ chối.
- **Chuyển tiếp SMS:** Owner nhận SMS (lọc theo whitelist người gửi), mã hóa bằng Channel Key của epoch hiện tại rồi đẩy lên server; thành viên nhận chuông FCM, tải tin về và giải mã trên máy.
- **Mã hóa:** Định danh thiết bị bằng khóa X25519; Channel Key được bọc (ECDH + AES-256-GCM) riêng cho từng thành viên. Khi có thành viên mới hoặc bị thu hồi, epoch xoay vòng để đảm bảo forward secrecy.
- **Sao lưu / khôi phục:** Xuất và nhập lại danh tính thiết bị và khóa kênh khi đổi máy.

## 2. Tính năng chính

| Module (`lib/features/`) | Chức năng |
| :--- | :--- |
| `channel`, `channel_detail` | Danh sách kênh, chi tiết kênh, duyệt / thu hồi thành viên, lịch sử yêu cầu |
| `qr_entry`, `scanner`, `channel_join` | Tạo mã QR mời, quét QR và xác nhận tham gia kênh |
| `sms` | Xem tin nhắn đã giải mã theo ngày |
| `activity` | Nhật ký hoạt động chuyển tiếp |
| `device` | Hồ sơ thiết bị, checklist cấu hình (quyền SMS, tối ưu pin, thông báo) |
| `settings` | Whitelist người gửi SMS |
| `backup` | Sao lưu và khôi phục |

## 3. Công nghệ

- **Flutter** (Dart SDK ^3.10), state management **BLoC + Equatable**, kiến trúc 3 tầng UI – BLoC – Data.
- **Firebase:** Cloud Messaging, Crashlytics, Analytics, Remote Config.
- **Mạng:** `dio`; **mã hóa:** `cryptography`, `crypto`; **lưu khóa:** `flutter_secure_storage`.
- Hạn chế code generation (không dùng `freezed` / `json_serializable`).

Quy tắc phát triển chi tiết: xem [`AGENTS.md`](AGENTS.md).

## 4. Bắt đầu

Yêu cầu: Flutter stable (dự án dùng [FVM](https://fvm.app), xem `.fvmrc`), Android SDK. Chức năng đọc/nhận SMS chỉ hoạt động trên **Android**.

1. Đặt file `google-services.json` của project Firebase vào `android/app/` (file này không được commit).
2. Cài dependencies và sinh file đa ngôn ngữ:

   ```bash
   flutter pub get
   flutter gen-l10n
   ```

3. Chạy ứng dụng:

   ```bash
   flutter run
   ```

Kiểm tra code:

```bash
flutter analyze
flutter test
```

## 5. Tài liệu liên quan

- [`docs/FLOW_AUDIT.md`](docs/FLOW_AUDIT.md) — rà soát luồng so với thiết kế.
- [`BACKLOG.md`](BACKLOG.md), [`REVIEW_BACKLOG.md`](REVIEW_BACKLOG.md) — công việc tồn đọng.
- Đặc tả API và cơ sở dữ liệu nằm ở repo server: `SERVER_API_SPEC.md`, `SRD_DATABASE.md`.

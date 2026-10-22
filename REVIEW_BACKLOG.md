# REVIEW BACKLOG — kiểm thử & rà soát nhánh `feat/backlog-sweep` (Mobile)

> Mỗi mục ứng với **một commit** trên nhánh (theo thứ tự ưu tiên P1 → P3).
> Tick khi đã rà soát code **và** test trên máy. Mục nào có ⚠️ cần quyết định / phối hợp trước khi merge.
> Nhánh tách từ `feat/otp-notification` — merge PR #1 trước, rồi rebase/merge nhánh này.
> BE tương ứng: `sms_navigator_server` nhánh `feat/backlog-sweep` (file `REVIEW_BACKLOG.md` cùng tên).

---

## P1-1 · `distribute.yml` ký bằng release keystore (BACKLOG 3.8)

**Rà soát**
- [ ] Workflow dừng ngay nếu thiếu `ANDROID_KEYSTORE_BASE64` / `ANDROID_KEYSTORE_PASSWORD` (không bao giờ build bản ký debug key của runner).
- [ ] Keystore giải mã vào `$RUNNER_TEMP`, xoá ở bước cuối (`if: always()`); không bị upload làm artifact.
- [ ] Flutter ghim `3.47.7` (cùng bản dev đã test).

**Kiểm thử**
- [ ] Thêm 3 secret (`base64 -i ~/.android/sms-navigator-release.jks | pbcopy`, mật khẩu trong `android/key.properties`, alias `upload`).
- [ ] Chạy tay workflow (Actions → *Distribute to Firebase App Tester* → Run workflow) trên một nhánh test → bước *Verify APK…* in `✅ APK ký bằng release keystore`.
- [ ] Bản tải từ App Tester **cài đè** được lên 1.1.0 đang có (không phải gỡ) và `pm get-app-links` vẫn `verified`.
- [ ] Xoá tạm 1 secret → job đỏ ở bước *Restore release keystore*.

## P1-2 · CI cho pull request (BACKLOG 3.9)

**Rà soát**
- [ ] `.github/workflows/ci.yml` chạy cho mọi `pull_request` + push `main`; không dùng secret.
- [ ] Job `flutter`: `gen-l10n` + `git diff --exit-code lib/l10n` (bắt l10n đã commit bị cũ), `analyze`, `test`.
- [ ] Job `android-unit`: `flutter build apk --config-only` sinh `gradlew`, rồi `:app:testDebugUnitTest`.

**Kiểm thử**
- [ ] Mở PR của nhánh này → 2 job xanh.
- [ ] (Tuỳ chọn) Settings → Branches → bảo vệ `main`, bắt buộc 2 check `Analyze & Flutter test`, `Kotlin unit tests`.

## P1-3 · Clean-cut v4 phía app (BACKLOG 0.6)

⚠️ **Thứ tự phát hành bắt buộc**: (1) mọi máy đã lên **1.1.0+20** → (2) Remote Config `app_update_min_build` = **20** (force update) → (3) deploy BE "clean-cut v4" → (4) phát bản app có commit này. Đảo thứ tự → máy cũ không join được kênh.

**Rà soát**
- [ ] Đã gỡ `InvitePayload`, `LegacyInviteLink`, `JoinResolveStarted`, `JoinPhase.resolving/resolveFailed`, `JoinSkeletonView`/`JoinErrorView`, `JoinChannelRepository.resolveInvite/claim`, `PairingApiService.resolveSession/claimPairingRequest`, endpoint `channelSessionsResolveV2`.
- [ ] `PairingSessionModel` chỉ còn `code`/`qrUrl` (`shareUrl == qrUrl`); bỏ qua `pairing_token`/`invite_url` nếu server cũ còn trả.
- [ ] `JoinBloc` bắt buộc `QrRepository`; `JoinConfirmPage` chỉ còn `.fromQr` (preview do `QrEntryPage` resolve).
- [ ] QR v4 (`smsnavigator://pair?v=4…`) giờ bị từ chối với toast "Mã QR này không được SMS Navigator hỗ trợ".
- [ ] Gỡ 3 chuỗi l10n không dùng (`joinResolveFailed`, `joinResolveFailedShort`, `joinInvalidQrFormat`).

**Kiểm thử**
- [ ] Owner tạo QR → Member quét bằng camera / chọn ảnh / bấm link / dán mã → màn xác nhận → gửi yêu cầu → Owner duyệt.
- [ ] Quét QR v4 cũ (ảnh chụp từ bản ≤ 1.0.x) → toast không hỗ trợ, không crash.
- [ ] Claim lỗi (mã đã dùng / hết hạn) → toast đúng thông điệp, ở lại màn xác nhận.

## P2-1 · Đổi tên kênh (BACKLOG 1.5)

Cần BE `PUT /api/v2/channels/name` (BE REVIEW_BACKLOG P2-1) đã deploy.

**Rà soát**
- [ ] Menu "⋮" mới trên AppBar chi tiết kênh (`ChannelDetailMenuButton`) — chỉ Owner thấy; các mục sau (lịch sử, lưu trữ, rời kênh) cũng nằm ở đây.
- [ ] Dialog dùng `DialogUtils.showInputDialog`, điền sẵn tên hiện tại, tối đa 100 ký tự (giống tạo kênh).
- [ ] `ChannelDetailRenamed`: bỏ qua tên rỗng/không đổi; thành công → refresh + `SyncOwnerRelayChannelUseCase()` để native relay cập nhật tên trong log.

**Kiểm thử**
- [ ] Owner: ⋮ → Đổi tên kênh → Lưu → tiêu đề AppBar + danh sách kênh đổi tên; toast "Đã đổi tên kênh thành …".
- [ ] Member mở cùng kênh (kéo để làm mới) → thấy tên mới.
- [ ] Gửi 1 SMS sau khi đổi tên → log relay trên máy Owner hiện "Kênh: <tên mới>".
- [ ] Tắt mạng rồi đổi tên → toast lỗi, tên cũ giữ nguyên.

## Fix · Thu hồi thành viên luôn thất bại (phát hiện khi làm P2-2)

`ChannelRepositoryImpl.revokeMembers` wrap key epoch mới cho **mọi** member ACTIVE, kể cả máy đang bị thu hồi → server trả `422 PACKAGE_INCOMPLETE` ("Unexpected: [máy bị thu hồi]") → nút Thu hồi luôn báo lỗi xung đột. (Nhờ server chặn nên key mới không lộ cho máy bị thu hồi.)

**Rà soát**
- [ ] Envelope set khi revoke = {Owner} ∪ ACTIVE − `revokeDeviceIds`.
- [ ] Test mới trong `channel_repository_rotation_test.dart` kiểm đúng tập device id.

**Kiểm thử**
- [ ] Trên máy thật: Owner thu hồi 1 member → thành công, member đó nhận thông báo, các member còn lại vẫn đọc được tin mới.
- [ ] ⚠️ Nên cherry-pick commit này sang `feat/otp-notification` / bản 1.1.x vì lỗi có ở bản đang phát hành.

## P2-2 · Rời kênh / giải tán kênh (BACKLOG 1.4)

Cần BE `POST /channels/leave|rotate|archive` (BE REVIEW_BACKLOG P2-2). Xem phần **Thiết kế** ở BE — leave không đổi epoch, Owner tự rotate.

**Rà soát**
- [ ] Menu ⋮: Owner = Đổi tên + **Giải tán kênh** (đỏ); Member = **Rời kênh** (đỏ). Cả hai qua `DialogUtils.showConfirmDialog(isDestructive: true)`.
- [ ] `ChannelRepositoryImpl.leaveChannel` purge key của kênh sau khi server xác nhận; `archiveChannel` rồi `SyncOwnerRelayChannelUseCase()` để native bỏ kênh.
- [ ] `rotateChannelKey` dùng chung `_rotate` (lưu + stage key trước, retry đúng package, discard khi 4xx) + re-encrypt whitelist.
- [ ] `SyncOwnerRelayChannelUseCase` gặp `rotation_pending` → rotate trước khi snapshot; lỗi thì giữ epoch cũ, thử lại lần sync sau. Kích hoạt khi: khởi động, resume, **mọi FCM foreground** (kể cả `MEMBER_LEFT`). App bị kill → rotate ở lần mở kế tiếp (relay vẫn chạy ở epoch cũ trong lúc chờ).
- [ ] `ChannelDetailState.isClosed` → màn chi tiết tự `maybePop`; `ChannelCardView` refresh danh sách khi quay về.
- [ ] `ChannelEventKind.memberLeft` (`MEMBER_LEFT`).

**Kiểm thử**
- [ ] Member: ⋮ → Rời kênh → xác nhận → về danh sách, kênh biến mất; SMS mới của kênh không còn hiện.
- [ ] Owner (app mở): nhận thông báo "X đã rời kênh" → epoch tăng 1 (xem tiêu đề thẻ kênh) → member còn lại vẫn đọc tin mới.
- [ ] Owner (app đã vuốt tắt) khi member rời → SMS vẫn relay; mở app → tự rotate.
- [ ] Owner: ⋮ → Giải tán kênh → member (cả bản 1.1.0) nhận "Kênh đã giải tán", kênh biến mất ở cả hai bên; SMS khớp whitelist kênh đó không còn relay.
- [ ] Tắt mạng rồi rời / giải tán → toast lỗi, ở lại màn chi tiết.

## P2-3 · Lịch sử yêu cầu kết nối (BACKLOG 1.6)

Cần BE `GET /channels/requests?status=HISTORY` (BE REVIEW_BACKLOG P2-3).

**Rà soát**
- [ ] Menu ⋮ (Owner) → "Lịch sử yêu cầu" → `RequestHistoryPage`: tên máy, thời điểm xử lý, nhãn Đã duyệt / Đã từ chối / Đã huỷ.
- [ ] `RequestHistoryCubit`: trang 30 mục, "Xem thêm" theo `next_before`, kéo để làm mới, màn lỗi có nút Thử lại.
- [ ] Model `RequestHistoryResult` (tên khác màn `RequestHistoryPage` để tránh trùng).

**Kiểm thử**
- [ ] Owner duyệt 1, từ chối 1; member huỷ 1 → lịch sử hiện đủ 3, mới nhất trên cùng.
- [ ] Kênh chưa có request đã xử lý → màn trống "Chưa có yêu cầu nào được xử lý."

## P2-4 · Nhắc tạo bản sao lưu (BACKLOG 1.9)

**Rà soát**
- [ ] `BackupRepositoryImpl` ghi `BackupRecord {at, channels}` vào `LocalStorageService` sau **export thành công** và sau **restore** (máy khôi phục coi như đã có bản sao lưu); huỷ hộp thoại lưu → không ghi.
- [ ] `BackupReminderCubit`: nhắc khi có ≥1 kênh **và** (chưa từng sao lưu **hoặc** có kênh chưa nằm trong bản gần nhất). Chỉ so **tập kênh**, không so epoch (key epoch mới tự lấy lại từ envelope).
- [ ] "Để sau" ẩn 3 ngày (`backup_reminder_snoozed_until`); "Sao lưu ngay" mở trang thiết bị, quay về thì đánh giá lại.
- [ ] Banner (`MaterialBanner`) nằm trên tab Kênh, phía trên 2 tab danh sách.
- [ ] ⚠️ Máy đang dùng (đã có kênh) sẽ thấy banner ngay sau khi cập nhật, vì trước đây chưa từng ghi lại lần sao lưu — đúng ý đồ (đã sao lưu ở 1.0.1 thì bấm Sao lưu lại một lần).

**Kiểm thử**
- [ ] Cài mới, tạo kênh → banner hiện. Sao lưu → quay lại → banner ẩn.
- [ ] Tham gia thêm 1 kênh → banner hiện lại.
- [ ] Bấm "Để sau" → ẩn; chỉnh giờ máy +3 ngày → hiện lại.
- [ ] Khôi phục từ bản sao lưu trên máy mới → không hiện banner (trừ khi đã có kênh mới sau bản đó).

## P2-5 · Keystore lỗi → không còn lưu thô âm thầm (BACKLOG 2.2)

**Quyết định** ⚠️: giữ **fail-open** (lưu thô khi `SecureVault` lỗi) vì fail-closed làm dừng hẳn relay trên ROM có Keystore chập chờn — nhưng mỗi lần đều được ghi lại, báo Crashlytics và cảnh báo người dùng. Nếu muốn fail-closed cho riêng nội dung SMS, đổi `RelayChannelStore.encrypt` ở chỗ gọi outbox/parked.

**Rà soát**
- [ ] Kotlin `VaultFallbackLog`: đếm + site + lỗi + thời điểm trong SharedPreferences; ghi ở `OtpPreferences` (device token, legacy channel key) và `RelayChannelStore.encrypt` (channel key, outbox, parked). `Log.w` được bọc try (JVM test).
- [ ] MethodChannel `takeVaultFallbackReport` = lấy rồi xoá.
- [ ] Dart `ReportVaultFallbackUseCase` chạy 1 lần trong `_AsyncServicesInitializer`: Crashlytics non-fatal (`reason: secure_vault_fallback`) + toast cảnh báo.
- [ ] Không có báo cáo → im lặng; báo cáo đã gửi không lặp lại.

**Kiểm thử**
- [ ] Unit: `VaultFallbackLogTest` (Kotlin), `report_vault_fallback_use_case_test.dart`.
- [ ] (Khó tái hiện trên máy thường) Trên thiết bị/emulator: xoá alias `otp_relay_master_key` trong Keystore bằng debugger → nhận 1 SMS → mở app → toast cảnh báo + event trên Crashlytics.

## P2-6 · Xử lý 401 tập trung (BACKLOG 3.2)

**Rà soát**
- [ ] `ApiClient.onUnauthorized` (gắn trong `AppBootstrap`, provider `DeviceApiService` giờ `lazy: false`): 401 trên request đã xác thực (không phải `/devices/register`, chưa retry) → `DeviceSessionRecovery` → retry **1 lần** với token mới; vẫn 401 → `UnauthorizedException` như cũ.
- [ ] `DeviceSessionRecovery`: đăng ký lại với **cùng** `device_id` + public key (server ghi đè `token_hash`, giữ membership/envelope), đẩy token mới xuống native (`setCredentials`); single-flight; lỗi → toast 1 lần + nghỉ 30 s; máy chưa từng đăng ký → bỏ qua (Splash lo).
- [ ] Native `OtpRelayWorker`: 401 → **park** SMS (trước đây bỏ hẳn), gửi lại khi app sync xong.
- [ ] ⚠️ Khi nào 401 xảy ra thật: token bị thay do máy khác khôi phục **cùng bản sao lưu** (cùng `device_id`) và đăng ký lại → hai máy sẽ "giành" token của nhau. Không nên khôi phục 1 bản sao lưu lên 2 máy đang chạy cùng lúc — cân nhắc thêm cảnh báo ở màn khôi phục.

**Kiểm thử**
- [ ] Unit: `api_client_unauthorized_test.dart`, `device_session_recovery_test.dart`.
- [ ] Trên máy: sửa `device_token` trong SharedPreferences (adb/root) thành chuỗi sai → mở tab Kênh → danh sách vẫn tải (log "Re-registered … after a 401").
- [ ] Tắt mạng trong lúc 401 → toast "Phiên của thiết bị đã hết hạn…" chỉ 1 lần.

## P3-1 · Tuỳ chọn thông báo cho chính máy relay (BACKLOG 1.8)

**Rà soát**
- [ ] `StorageKeys.notifyOwnRelayedMessages` (mặc định **tắt** = hành vi hiện tại). `NewMessageNotifier` đọc qua `preferences` ở cả foreground (`FcmNotificationServiceImpl`) và background isolate (`fcm_background_handler` tạo `LocalStorageService` riêng → đọc giá trị mới nhất từ đĩa).
- [ ] Công tắc trong "Cài đặt & tuỳ chọn" của trang thiết bị (`NotifyOwnRelayedTile`, ẩn nếu không có LocalStorageService).

**Kiểm thử**
- [ ] Máy Owner: bật công tắc → nhận 1 SMS OTP → máy Owner cũng hiện thông báo OTP. Tắt → không hiện.
- [ ] Thử khi app bị vuốt tắt (background isolate).


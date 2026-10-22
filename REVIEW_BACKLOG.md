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


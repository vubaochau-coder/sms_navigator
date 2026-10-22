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


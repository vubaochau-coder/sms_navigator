/// Nguồn deeplink từ hệ điều hành (App Links / Universal Links / custom scheme).
///
/// [links] phát cả link mở app lúc cold start lẫn link đến khi app đang chạy
/// (warm start). Tách interface để test không phụ thuộc plugin.
abstract class DeepLinkService {
  Stream<Uri> get links;
}

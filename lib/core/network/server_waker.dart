import 'dart:async';

import 'package:dio/dio.dart';

import '../utils/app_logger.dart';

/// Phân loại phản hồi: request bị chặn ở tầng edge (Cloudflare / Render)
/// trước khi tới server Node, hay là phản hồi thật của server.
///
/// Server luôn trả envelope JSON có khoá `success` — kể cả 429 `RATE_LIMITED`
/// của express-rate-limit. Vì vậy 403/429/503 **không** mang envelope đó
/// (trang challenge HTML `Just a moment...`, `Too Many Requests` dạng text của
/// Render) nghĩa là request chưa từng tới server.
bool isEdgeBlockedResponse(Response<dynamic>? response) {
  if (response == null) return false;
  const edgeStatuses = {403, 429, 503};
  if (!edgeStatuses.contains(response.statusCode)) return false;
  final data = response.data;
  return !(data is Map && data.containsKey('success'));
}

/// Đánh thức server Render free-tier khi nó đang ngủ.
///
/// Bối cảnh: app gọi API qua Cloudflare Worker → Render. Khi service ngủ
/// (15 phút không có request), Cloudflare của Render trả trang challenge
/// (HTTP 429) cho traffic từ Worker thay vì đánh thức service — app kẹt mãi.
/// Gọi thẳng URL Render thì (thường) đánh thức được.
///
/// Chiến lược (cố ý hẹp để URL trực tiếp không trở thành đường đi thứ hai):
/// 1. **Chỉ một endpoint**: `GET <render>/health` — không token, không body,
///    không dữ liệu người dùng. Mọi API thật vẫn chỉ đi qua Worker.
/// 2. **Chỉ khi** request qua Worker mặc định bị chặn ở edge
///    ([isEdgeBlockedResponse]); server tuỳ chỉnh / lỗi JSON của server
///    không bao giờ kích hoạt.
/// 3. **Single-flight**: nhiều request bị chặn cùng lúc dùng chung một lần ping.
/// 4. **Cooldown** [cooldown] sau mỗi lần ping (thành công hay thất bại): trong
///    khoảng đó trả lại kết quả cũ, không ping thêm — Render cũng rate-limit
///    traffic dồn dập vào service đang ngủ.
/// 5. **Có giới hạn thời gian** [pingTimeout] (cold start ~30–60 s).
/// 6. Ping thành công → caller gửi lại request gốc qua Worker **đúng một lần**.
///    An toàn cả với POST: bị chặn ở edge nghĩa là server chưa xử lý gì.
///    Ping thất bại / vẫn bị chặn → báo "máy chủ đang khởi động" cho người dùng.
class ServerWaker {
  ServerWaker({
    Dio? dio,
    this.wakeUrl = defaultWakeUrl,
    this.pingTimeout = const Duration(seconds: 60),
    this.cooldown = const Duration(seconds: 90),
    DateTime Function()? clock,
  }) : _dio = dio ?? Dio(BaseOptions(connectTimeout: pingTimeout)),
       _clock = clock ?? DateTime.now;

  /// Health endpoint gọi thẳng Render (bỏ qua Worker).
  static const String defaultWakeUrl = 'https://sms-navigator-server.onrender.com/health';

  final Dio _dio;
  final String wakeUrl;
  final Duration pingTimeout;
  final Duration cooldown;
  final DateTime Function() _clock;

  Future<bool>? _inFlight;
  DateTime? _lastAttemptAt;
  bool _lastResult = false;

  /// `true` khi server đã thức (ping trả `status: healthy`). Không bao giờ ném lỗi.
  Future<bool> wake() {
    final inFlight = _inFlight;
    if (inFlight != null) return inFlight;

    final last = _lastAttemptAt;
    if (last != null && _clock().difference(last) < cooldown) {
      return Future<bool>.value(_lastResult);
    }

    final attempt = _ping().then((ok) {
      _lastAttemptAt = _clock();
      _lastResult = ok;
      _inFlight = null;
      return ok;
    });
    _inFlight = attempt;
    return attempt;
  }

  Future<bool> _ping() async {
    final started = _clock();
    try {
      final response = await _dio.get<dynamic>(
        wakeUrl,
        options: Options(
          sendTimeout: pingTimeout,
          receiveTimeout: pingTimeout,
          responseType: ResponseType.json,
          headers: <String, dynamic>{'Accept': 'application/json'},
          validateStatus: (_) => true,
        ),
      ).timeout(pingTimeout);
      final data = response.data;
      final ok = response.statusCode == 200 && data is Map && data['status'] == 'healthy';
      final elapsed = _clock().difference(started).inMilliseconds;
      if (ok) {
        AppLogger.i('ServerWaker', 'Server is awake after ${elapsed}ms');
      } else {
        AppLogger.w('ServerWaker', 'Wake ping got HTTP ${response.statusCode} after ${elapsed}ms');
      }
      return ok;
    } catch (e) {
      AppLogger.w('ServerWaker', 'Wake ping failed', e);
      return false;
    }
  }
}

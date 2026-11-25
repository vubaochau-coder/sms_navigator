import 'dart:async';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../utils/app_logger.dart';

/// Phân loại phản hồi: request bị chặn ở tầng edge (Cloudflare / Render)
/// trước khi tới server Node, hay là phản hồi thật của server.
///
/// Server luôn trả envelope JSON có khoá `success` — kể cả 429 `RATE_LIMITED`
/// của express-rate-limit. Vì vậy 403/429/503 **không** mang envelope đó
/// (trang challenge HTML `Just a moment...`, `Too Many Requests` dạng text kèm
/// `x-render-routing: hibernate-rate-limited`) nghĩa là request chưa tới server.
bool isEdgeBlockedResponse(Response<dynamic>? response) {
  if (response == null) return false;
  const edgeStatuses = {403, 429, 503};
  if (!edgeStatuses.contains(response.statusCode)) return false;
  final data = response.data;
  return !(data is Map && data.containsKey('success'));
}

/// Đánh thức server Render free-tier khi nó đang ngủ.
///
/// Bối cảnh: Render có "hibernation gate" cho service free đang ngủ — thay vì
/// giữ request tới khi khởi động xong như trước, nó trả 429 ngay
/// (`x-render-routing: hibernate-rate-limited`, hoặc challenge Cloudflare).
/// Request qua Worker (IP egress dùng chung của Cloudflare) gần như luôn bị
/// từ chối; request thẳng tới địa chỉ Render mới đánh thức được, và việc khởi
/// động mất khoảng 1 phút, trong lúc đó gate vẫn trả 429.
///
/// Chiến lược:
/// 1. **Chỉ một endpoint**: `GET <render>/health` — không token, không body.
///    Mọi API thật vẫn chỉ đi qua Worker.
/// 2. **Chỉ khi** request qua Worker mặc định bị chặn ở edge
///    ([isEdgeBlockedResponse]).
/// 3. **Polling có giãn cách** ([pollDelays], tôn trọng `Retry-After`) tới khi
///    `/health` trả `healthy` hoặc hết [wakeDeadline]. 429/503/challenge trong
///    lúc chờ = "đang khởi động", tiếp tục chờ.
/// 4. **Single-flight**: mọi request bị chặn dùng chung một vòng polling;
///    [waking] báo cho UI ("Đang đánh thức máy chủ…").
/// 5. **Cooldown** sau khi kết thúc: thành công → [successCooldown] trả `true`
///    luôn; thất bại → [failureCooldown] trả `false` luôn (không spam Render).
/// 6. Thức → caller gửi lại request gốc qua Worker **đúng một lần**. Không
///    thức → UI đề nghị mở `/health` bằng trình duyệt ([wakeUri]) — trình
///    duyệt vượt được bước kiểm tra bot mà HTTP client của app có thể không.
class ServerWaker {
  ServerWaker({
    Dio? dio,
    String wakeUrl = defaultWakeUrl,
    this.wakeDeadline = const Duration(seconds: 150),
    this.attemptTimeout = const Duration(seconds: 60),
    this.pollDelays = const [
      Duration(seconds: 3),
      Duration(seconds: 5),
      Duration(seconds: 8),
      Duration(seconds: 10),
    ],
    this.successCooldown = const Duration(seconds: 60),
    this.failureCooldown = const Duration(seconds: 30),
    DateTime Function()? clock,
    Future<void> Function(Duration)? sleep,
  }) : wakeUri = Uri.parse(wakeUrl),
       _dio = dio ?? Dio(BaseOptions(connectTimeout: attemptTimeout)),
       _clock = clock ?? DateTime.now,
       _sleep = sleep ?? Future<void>.delayed;

  /// Health endpoint gọi thẳng Render (bỏ qua Worker).
  static const String defaultWakeUrl = 'https://sms-navigator-server.onrender.com/health';

  /// Địa chỉ mở bằng trình duyệt khi app không tự đánh thức được.
  final Uri wakeUri;
  final Duration wakeDeadline;
  final Duration attemptTimeout;

  /// Khoảng chờ giữa các lần ping; phần tử cuối lặp lại tới hết hạn.
  final List<Duration> pollDelays;
  final Duration successCooldown;
  final Duration failureCooldown;

  final Dio _dio;
  final DateTime Function() _clock;
  final Future<void> Function(Duration) _sleep;

  final ValueNotifier<bool> _waking = ValueNotifier<bool>(false);

  /// `true` trong lúc đang polling đánh thức server.
  ValueListenable<bool> get waking => _waking;

  Future<bool>? _inFlight;
  DateTime? _finishedAt;
  bool _lastResult = false;

  /// `true` khi server đã thức (ping trả `status: healthy`). Không bao giờ ném lỗi.
  Future<bool> wake() {
    final inFlight = _inFlight;
    if (inFlight != null) return inFlight;

    final finished = _finishedAt;
    if (finished != null) {
      final cooldown = _lastResult ? successCooldown : failureCooldown;
      if (_clock().difference(finished) < cooldown) {
        return Future<bool>.value(_lastResult);
      }
    }

    _waking.value = true;
    final attempt = _poll().then((ok) {
      _finishedAt = _clock();
      _lastResult = ok;
      _inFlight = null;
      _waking.value = false;
      return ok;
    });
    _inFlight = attempt;
    return attempt;
  }

  /// Quên kết quả cũ — vd. người dùng vừa đánh thức bằng trình duyệt.
  void resetCooldown() => _finishedAt = null;

  Future<bool> _poll() async {
    final started = _clock();
    var attempt = 0;
    while (true) {
      final result = await _ping();
      attempt++;
      final elapsed = _clock().difference(started);
      if (result.awake) {
        AppLogger.i('ServerWaker', 'Server is awake after ${elapsed.inSeconds}s ($attempt ping(s))');
        return true;
      }
      var delay = pollDelays[math.min(attempt - 1, pollDelays.length - 1)];
      final retryAfter = result.retryAfter;
      if (retryAfter != null && retryAfter > delay) {
        delay = retryAfter > const Duration(seconds: 30) ? const Duration(seconds: 30) : retryAfter;
      }
      if (elapsed + delay >= wakeDeadline) {
        AppLogger.w('ServerWaker', 'Server still asleep after ${elapsed.inSeconds}s ($attempt ping(s)), giving up');
        return false;
      }
      await _sleep(delay);
    }
  }

  Future<_PingResult> _ping() async {
    try {
      final response = await _dio
          .get<dynamic>(
            wakeUri.toString(),
            options: Options(
              sendTimeout: attemptTimeout,
              receiveTimeout: attemptTimeout,
              responseType: ResponseType.json,
              headers: <String, dynamic>{'Accept': 'application/json'},
              validateStatus: (_) => true,
            ),
          )
          .timeout(attemptTimeout);
      final data = response.data;
      final awake = response.statusCode == 200 && data is Map && data['status'] == 'healthy';
      if (!awake) {
        final routing = response.headers.value('x-render-routing');
        AppLogger.w('ServerWaker', 'Wake ping: HTTP ${response.statusCode}${routing != null ? ' ($routing)' : ''}');
      }
      return _PingResult(awake, _parseRetryAfter(response.headers.value('retry-after')));
    } catch (e) {
      AppLogger.w('ServerWaker', 'Wake ping failed', e);
      return const _PingResult(false, null);
    }
  }

  static Duration? _parseRetryAfter(String? raw) {
    final seconds = int.tryParse(raw?.trim() ?? '');
    return seconds == null || seconds <= 0 ? null : Duration(seconds: seconds);
  }
}

class _PingResult {
  const _PingResult(this.awake, this.retryAfter);
  final bool awake;
  final Duration? retryAfter;
}

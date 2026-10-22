import 'package:equatable/equatable.dart';

import '../../../core/models/invite_preview_model.dart';

abstract class JoinEvent extends Equatable {
  const JoinEvent();

  @override
  List<Object?> get props => [];
}

/// Mở từ Universal Opaque QR: preview đã có sẵn từ `GET /qr/resolve`
/// (roadmap v3.3 §3.4) → vào thẳng trạng thái ready, không resolve lại.
class JoinInitializedWithPreview extends JoinEvent {
  final InvitePreviewModel preview;
  final String code;

  const JoinInitializedWithPreview({required this.preview, required this.code});

  @override
  List<Object?> get props => [preview, code];
}

/// Bấm [Gửi yêu cầu kết nối] — claim QR với tên thiết bị hiện tại (read-only).
class JoinSubmitted extends JoinEvent {
  final String deviceName;

  const JoinSubmitted(this.deviceName);

  @override
  List<Object?> get props => [deviceName];
}

import 'package:equatable/equatable.dart';

import 'invite_preview_model.dart';

/// Kết quả `GET /api/v2/qr/resolve` đã được map sang nghiệp vụ.
sealed class QrResolution extends Equatable {
  const QrResolution();
}

/// `type = PAIRING`: lời mời tham gia kênh (preview, không kèm token).
class PairingQrResolution extends QrResolution {
  final String code;
  final InvitePreviewModel preview;

  const PairingQrResolution({required this.code, required this.preview});

  @override
  List<Object?> get props => [code, preview];
}

/// Server biết loại QR này nhưng bản app hiện tại thì chưa → cần cập nhật app.
class UnsupportedQrResolution extends QrResolution {
  final String type;

  const UnsupportedQrResolution(this.type);

  @override
  List<Object?> get props => [type];
}

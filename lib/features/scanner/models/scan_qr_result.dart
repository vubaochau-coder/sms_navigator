import 'package:equatable/equatable.dart';

/// Kết quả trả về từ màn hình quét QR.
class ScanQrResult extends Equatable {
  final String rawValue;

  const ScanQrResult({required this.rawValue});

  @override
  List<Object?> get props => [rawValue];
}

import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;

/// Canonical encoding dùng CHUNG bởi mọi phía (SRD 7.1) — cấm nối string tự do.
///
/// ```text
/// bind(ch, epoch, seq)  = "sms-navigator-msg-v1" || u32(len(ch)) || ch || u64(epoch) || u64(seq)
/// bind(ch, epoch, dev)  = "sms-navigator-env-v1" || u32(len(ch)) || ch || u64(epoch) || u32(len(dev)) || dev
/// ```
/// (`u32`/`u64` little-endian.)
abstract final class CanonicalEncoding {
  static const String _msgDomain = 'sms-navigator-msg-v1';
  static const String _envDomain = 'sms-navigator-env-v1';
  static const String _saltDomain = 'sms-navigator-salt-v1';

  static Uint8List _u32le(int value) =>
      Uint8List(4)..buffer.asByteData().setUint32(0, value & 0xFFFFFFFF, Endian.little);

  static Uint8List _u64le(int value) {
    final bytes = Uint8List(8);
    bytes.buffer.asByteData().setUint64(0, value, Endian.little);
    return bytes;
  }

  static Uint8List _lenPrefixedString(String value) {
    final raw = utf8.encode(value);
    return Uint8List.fromList([..._u32le(raw.length), ...raw]);
  }

  /// AAD của message: ràng buộc (channel, epoch, sequence) — KL10.
  /// Owner mã hóa trước khi biết sequence nên dùng `sequenceHint = 0`
  /// (API spec §11); phía decrypt cũng dùng đúng hint đó.
  static Uint8List messageAad({
    required String channelId,
    required int keyEpoch,
    int sequenceHint = 0,
  }) {
    final parts = BytesBuilder();
    parts.add(utf8.encode(_msgDomain));
    parts.add(_lenPrefixedString(channelId));
    parts.add(_u64le(keyEpoch));
    parts.add(_u64le(sequenceHint));
    return parts.toBytes();
  }

  /// AAD của envelope: ràng buộc (channel, epoch, device) — KL9.
  static Uint8List envelopeAad({
    required String channelId,
    required int keyEpoch,
    required String deviceId,
  }) {
    final parts = BytesBuilder();
    parts.add(utf8.encode(_envDomain));
    parts.add(_lenPrefixedString(channelId));
    parts.add(_u64le(keyEpoch));
    parts.add(_lenPrefixedString(deviceId));
    return parts.toBytes();
  }

  /// Salt của KEK (SRD 7.2): gắn channel + epoch chống cross-channel /
  /// cross-epoch KEK reuse.
  /// `SHA256("sms-navigator-salt-v1" || u32(len(ch)) || ch || u64(epoch))`
  static Uint8List kekSalt({required String channelId, required int keyEpoch}) {
    final parts = BytesBuilder();
    parts.add(utf8.encode(_saltDomain));
    parts.add(_lenPrefixedString(channelId));
    parts.add(_u64le(keyEpoch));
    return Uint8List.fromList(crypto.sha256.convert(parts.toBytes()).bytes);
  }
}

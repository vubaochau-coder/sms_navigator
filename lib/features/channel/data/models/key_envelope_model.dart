import 'package:equatable/equatable.dart';

import '../../../../core/utils/data_converter.dart';

/// Key envelope của caller — `GET /api/v2/channels/key-envelope` (SRD 3.6):
/// Channel Key được wrap bằng KEK = HKDF(ECDH(sk_my, pk_owner)).
class KeyEnvelopeModel extends Equatable {
  final int keyEpoch;
  final String wrappedKey;
  final String nonce;
  final String kekAlg;

  const KeyEnvelopeModel({
    required this.keyEpoch,
    required this.wrappedKey,
    required this.nonce,
    this.kekAlg = 'X25519-ECDH-HKDF-SHA256/AES-256-GCM',
  });

  factory KeyEnvelopeModel.fromMap(Map<String, dynamic> map) {
    return KeyEnvelopeModel(
      keyEpoch: DataConverter.cvToInt(map['key_epoch'], 1)!,
      wrappedKey: DataConverter.cvToString(map['wrapped_key'], '')!,
      nonce: DataConverter.cvToString(map['nonce'], '')!,
      kekAlg: DataConverter.cvToString(
        map['kek_alg'],
        'X25519-ECDH-HKDF-SHA256/AES-256-GCM',
      )!,
    );
  }

  @override
  List<Object?> get props => [keyEpoch, wrappedKey, nonce, kekAlg];
}

/// Một envelope trong Package Pattern (API spec §8) — Owner xây trước khi
/// POST create/approve/revoke.
class PackageEnvelopeModel extends Equatable {
  final String deviceId;
  final int keyEpoch;
  final String wrappedKey;
  final String nonce;
  final String kekAlg;

  const PackageEnvelopeModel({
    required this.deviceId,
    required this.keyEpoch,
    required this.wrappedKey,
    required this.nonce,
    required this.kekAlg,
  });

  Map<String, dynamic> toMap() => {
    'device_id': deviceId,
    'key_epoch': keyEpoch,
    'wrapped_key': wrappedKey,
    'nonce': nonce,
    'kek_alg': kekAlg,
  };

  @override
  List<Object?> get props => [deviceId, keyEpoch, wrappedKey, nonce, kekAlg];
}

/// Package Pattern chuẩn (API spec §8): snapshot (base_epoch,
/// base_membership_version) + envelope set đầy đủ theo bảng SRD 4.1.
class PackageModel extends Equatable {
  final int baseEpoch;
  final int baseMembershipVersion;
  final List<PackageEnvelopeModel> envelopes;

  const PackageModel({
    required this.baseEpoch,
    required this.baseMembershipVersion,
    required this.envelopes,
  });

  Map<String, dynamic> toMap() => {
    'base_epoch': baseEpoch,
    'base_membership_version': baseMembershipVersion,
    'envelopes': envelopes.map((e) => e.toMap()).toList(),
  };

  @override
  List<Object?> get props => [baseEpoch, baseMembershipVersion, envelopes];
}

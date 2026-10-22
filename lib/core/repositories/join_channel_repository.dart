import '../models/pairing_request_model.dart';

abstract class JoinChannelRepository {
  // Preview + claim bằng opaque QR code: xem `QrRepository`.

  /// Trạng thái các request mình đã gửi.
  Future<List<PairingRequestModel>> listMyRequests();

  /// Hủy request (3.5) — chỉ khi còn PENDING.
  Future<void> cancelRequest(String requestId);

  /// Key provisioning ngầm (SRD 7.3): sau khi được duyệt (APPROVED).
  Future<int?> provisionChannelKey({
    required String channelId,
    required String ownerPublicKeyBase64,
  });

  /// Provision sau APPROVED khi chưa biết pk_owner.
  Future<int?> provisionLatestForApproved({required String channelId});

  /// Purge key material của 1 kênh (SRD 8.4/KL12) — khi bị revoke.
  Future<void> purgeChannelKeys(String channelId);
}

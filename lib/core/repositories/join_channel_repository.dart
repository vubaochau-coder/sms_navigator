import '../models/invite_preview_model.dart';
import '../models/pairing_request_model.dart';
import '../models/pairing_session_model.dart';

abstract class JoinChannelRepository {
  /// Xem trước thông tin kênh từ QR invite trước khi gửi yêu cầu tham gia (API spec §4.6).
  Future<InvitePreviewModel> resolveInvite(InvitePayload invite);

  /// Claim với tên thiết bị user nhập/sửa trong dialog xác nhận (3.2).
  Future<ClaimRequestResultModel> claim({
    required InvitePayload invite,
    required String deviceName,
  });

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

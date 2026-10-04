import '../models/channel_detail_model.dart';
import '../models/channel_member_model.dart';
import '../models/channel_model.dart';
import '../models/pairing_request_model.dart';
import '../models/pairing_session_model.dart';

abstract class ChannelRepository {
  /// `GET /channels` — nguồn cho ChannelListPage 2 nhóm theo `role` (2.1).
  Future<List<ChannelModel>> listChannels();

  /// `GET /channels/detail` — chi tiết kênh + trạng thái caller (2.3/2.4).
  Future<ChannelDetailModel> getChannelDetail(String channelId);

  /// `GET /channels/members` — danh sách thành viên (2.3).
  Future<List<ChannelMemberModel>> getMembers(String channelId);

  /// `GET /channels/requests?status=PENDING` — hàng đợi duyệt (4.1).
  Future<List<PairingRequestModel>> listPendingRequests(String channelId);

  /// Tạo kênh (2.2): Owner sinh channel_id + CK_1 + self-envelope -> POST.
  Future<ChannelModel> createChannel(String name);

  /// Duyệt 1 request (4.2): rotate -> sinh CK_(N+1) -> POST.
  Future<int> approveRequest({
    required String channelId,
    required PairingRequestModel request,
  });

  /// Từ chối 1 request (4.3).
  Future<void> rejectRequest(String requestId);

  /// Thu hồi thành viên (4.4): rotate -> sinh CK_(N+1) -> POST.
  Future<int> revokeMembers({
    required String channelId,
    required List<String> revokeDeviceIds,
  });

  /// Tạo QR invitation (deeplink v4, countdown 10').
  Future<PairingSessionModel> createPairingSession(String channelId);

  /// Cập nhật tên thiết bị.
  Future<void> renameDevice(String deviceName);

  /// Fetch envelope mới nhất -> unwrap -> persist CK.
  Future<int?> provisionLatestChannelKey({
    required String channelId,
    required String ownerPublicKeyBase64,
  });
}

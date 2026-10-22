import '../models/channel_detail_model.dart';
import '../models/channel_member_model.dart';
import '../models/channel_model.dart';
import '../models/pairing_request_model.dart';
import '../models/pairing_session_model.dart';
import '../models/request_history_result.dart';
import '../models/whitelist_config_model.dart';

abstract class ChannelRepository {
  /// `GET /channels` — nguồn cho ChannelPage 2 nhóm theo `role` (2.1).
  Future<List<ChannelModel>> listChannels();

  /// Như [listChannels] nhưng gắn white-list đã giải mã vào từng kênh để hiện
  /// pill trên danh sách. Best-effort: kênh không giải mã được → `whitelist` null.
  Future<List<ChannelModel>> listChannelsWithWhitelist();

  /// Giải mã white-list của một kênh để hiển thị (chỉ xem). Ưu tiên blob từ
  /// server; Owner fallback về cache native khi server chưa trả blob. Lỗi → null.
  Future<WhitelistConfigModel?> readWhitelist({
    required String channelId,
    required bool isOwner,
    ChannelWhitelistBlobModel? blob,
  });

  /// `GET /channels/detail` — chi tiết kênh + trạng thái caller (2.3/2.4).
  Future<ChannelDetailModel> getChannelDetail(String channelId);

  /// `GET /channels/members` — danh sách thành viên (2.3).
  Future<List<ChannelMemberModel>> getMembers(String channelId);

  /// `GET /channels/requests?status=PENDING` — hàng đợi duyệt (4.1).
  Future<List<PairingRequestModel>> listPendingRequests(String channelId);

  /// Lịch sử request đã xử lý của kênh (BACKLOG 1.6), mới nhất trước.
  Future<RequestHistoryResult> listRequestHistory(String channelId, {String? before});

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

  /// Owner đổi tên kênh (BACKLOG 1.5) — chỉ là metadata, không rotate key.
  Future<void> renameChannel({required String channelId, required String name});

  /// Member tự rời kênh (BACKLOG 1.4) — xoá luôn key của kênh trên máy.
  Future<void> leaveChannel(String channelId);

  /// Owner giải tán kênh (BACKLOG 1.4) — không hoàn tác.
  Future<void> archiveChannel(String channelId);

  /// Owner xoay khóa sau khi có member tự rời (`rotation_pending`) → epoch mới.
  Future<int> rotateChannelKey(String channelId);

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

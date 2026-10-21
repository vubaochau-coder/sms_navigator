import 'package:sms_navigator/core/models/pairing_request_model.dart';
import 'package:sms_navigator/core/models/qr_resolution.dart';
import 'package:sms_navigator/core/repositories/qr_repository.dart';

class FakeQrRepository implements QrRepository {
  Set<String> hosts = {'sms-relay.hirusakunasaga.workers.dev'};
  Object? resolveError;
  QrResolution? resolution;
  final List<String> claimedCodes = [];

  @override
  Future<Set<String>> allowedLinkHosts() async => hosts;

  @override
  Future<QrResolution> resolve(String code) async {
    final error = resolveError;
    if (error != null) throw error;
    return resolution!;
  }

  @override
  Future<ClaimRequestResultModel> claimPairing({required String code, required String deviceName}) async {
    claimedCodes.add(code);
    return ClaimRequestResultModel(
      requestId: 'req-1',
      channelId: 'ch-1',
      channelName: 'Kênh',
      ownerDeviceName: 'Owner',
    );
  }
}

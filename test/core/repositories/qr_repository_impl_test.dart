import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/models/pairing_request_model.dart';
import 'package:sms_navigator/core/models/qr_resolution.dart';
import 'package:sms_navigator/core/repositories/impls/qr_repository_impl.dart';
import 'package:sms_navigator/core/services/device_storage_service.dart';
import 'package:sms_navigator/core/services/qr_api_service.dart';

class _Api implements QrApiService {
  Map<String, dynamic> body = {};

  @override
  Future<Map<String, dynamic>> resolve(String code) async => body;

  @override
  Future<ClaimRequestResultModel> claimPairingByCode({required String code, required String deviceName}) async =>
      throw UnimplementedError();
}

class _Storage implements DeviceStorageService {
  String? serverUrl;

  @override
  Future<String?> getServerUrl() async => serverUrl;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError('${invocation.memberName}');
}

void main() {
  const code = 'AbCdEfGhIjKlMnOpQrSt_-';
  late _Api api;
  late _Storage storage;
  late QrRepositoryImpl repo;

  setUp(() {
    api = _Api();
    storage = _Storage();
    repo = QrRepositoryImpl(qrApiService: api, deviceStorage: storage);
  });

  test('PAIRING body maps to a preview without any token', () async {
    api.body = {
      'success': true,
      'type': 'PAIRING',
      'version': 1,
      'data': {
        'channel_id': 'ch-1',
        'channel_name': 'Kênh VCB OTP',
        'owner_device_name': 'Pixel 7 Pro',
        'expires_at': '2026-10-21T10:10:00.000Z',
      },
    };

    final resolution = await repo.resolve(code);

    expect(resolution, isA<PairingQrResolution>());
    final pairing = resolution as PairingQrResolution;
    expect(pairing.code, code);
    expect(pairing.preview.channelName, 'Kênh VCB OTP');
    expect(pairing.preview.ownerDeviceName, 'Pixel 7 Pro');
  });

  test('a type this build does not know → UnsupportedQrResolution', () async {
    api.body = {'type': 'BACKUP', 'version': 1, 'data': {}};
    expect(await repo.resolve(code), const UnsupportedQrResolution('BACKUP'));
  });

  test('allowed hosts include the configured server and the default base URL', () async {
    storage.serverUrl = 'https://My.Server.dev';
    final hosts = await repo.allowedLinkHosts();
    expect(hosts, contains('my.server.dev'));
    expect(hosts, contains('sms-relay.hirusakunasaga.workers.dev'));
  });
}

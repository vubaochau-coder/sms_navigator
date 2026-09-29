import '../../features/device/data/services/device_api_service.dart';
import '../../features/pairing/data/repositories/pairing_repository.dart';
import '../../features/pairing/data/services/pairing_service.dart';
import '../../features/receiver/data/repositories/receiver_repository.dart';
import '../../features/receiver/data/services/receiver_storage_service.dart';
import '../../features/sender/data/repositories/sender_repository.dart';
import '../../features/sender/data/services/native_relay_service.dart';
import '../network/api_client.dart';
import '../services/device_storage_service.dart';
import '../services/fcm_notification_service.dart';

class DependencyContainer {
  DependencyContainer._();

  static final DependencyContainer instance = DependencyContainer._();

  bool _initialized = false;

  late final NativeRelayService nativeRelayService;
  late final SenderRepository senderRepository;

  late final PairingService pairingService;
  late final PairingRepository pairingRepository;

  late final ReceiverStorageService receiverStorageService;
  late final ReceiverRepository receiverRepository;

  late final DeviceStorageService deviceStorageService;
  late final ApiClient apiClient;
  late final DeviceApiService deviceApiService;
  late final FcmNotificationService fcmNotificationService;

  void init() {
    if (_initialized) return;
    _initialized = true;

    nativeRelayService = NativeRelayServiceImpl();

    deviceStorageService = DeviceStorageServiceImpl();
    apiClient = ApiClient(
      serverUrlProvider: deviceStorageService.getServerUrl,
      tokenProvider: deviceStorageService.getDeviceToken,
    );
    deviceApiService = DeviceApiServiceImpl(
      apiClient: apiClient,
      storageService: deviceStorageService,
    );

    senderRepository = SenderRepositoryImpl(nativeService: nativeRelayService);

    pairingService = PairingServiceImpl(
      nativeService: nativeRelayService,
      apiClient: apiClient,
      deviceApiService: deviceApiService,
      deviceStorageService: deviceStorageService,
    );
    pairingRepository = PairingRepositoryImpl(pairingService: pairingService);

    receiverStorageService = ReceiverStorageServiceImpl();
    receiverRepository = ReceiverRepositoryImpl(
      storageService: receiverStorageService,
      pairingService: pairingService,
      apiClient: apiClient,
      deviceApiService: deviceApiService,
    );

    fcmNotificationService = FcmNotificationService(
      deviceStorageService: deviceStorageService,
      deviceApiService: deviceApiService,
      receiverStorageService: receiverStorageService,
    );
  }
}

import '../../features/pairing/data/repositories/pairing_repository.dart';
import '../../features/pairing/data/services/pairing_service.dart';
import '../../features/receiver/data/repositories/receiver_repository.dart';
import '../../features/receiver/data/services/receiver_storage_service.dart';
import '../../features/sender/data/repositories/sender_repository.dart';
import '../../features/sender/data/services/native_relay_service.dart';

class DependencyContainer {
  DependencyContainer._();

  static final DependencyContainer instance = DependencyContainer._();

  late final NativeRelayService nativeRelayService;
  late final SenderRepository senderRepository;

  late final PairingService pairingService;
  late final PairingRepository pairingRepository;

  late final ReceiverStorageService receiverStorageService;
  late final ReceiverRepository receiverRepository;

  void init() {
    nativeRelayService = NativeRelayServiceImpl();
    senderRepository = SenderRepositoryImpl(nativeService: nativeRelayService);

    pairingService = PairingServiceImpl(nativeService: nativeRelayService);
    pairingRepository = PairingRepositoryImpl(pairingService: pairingService);

    receiverStorageService = ReceiverStorageServiceImpl();
    receiverRepository = ReceiverRepositoryImpl(storageService: receiverStorageService);
  }
}

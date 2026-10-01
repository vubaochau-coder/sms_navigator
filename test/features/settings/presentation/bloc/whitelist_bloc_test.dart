import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/features/sender/data/models/whitelist_config_model.dart';
import 'package:sms_navigator/features/settings/data/repositories/whitelist_repository.dart';
import 'package:sms_navigator/features/settings/presentation/bloc/whitelist_bloc.dart';
import 'package:sms_navigator/features/settings/presentation/bloc/whitelist_event.dart';

class _FakeWhitelistRepository implements WhitelistRepository {
  WhitelistConfigModel stored = const WhitelistConfigModel();
  bool shouldFailSave = false;
  bool shouldFailLoad = false;
  int saveCallCount = 0;

  @override
  Future<WhitelistConfigModel> getWhitelist() async {
    if (shouldFailLoad) {
      throw Exception('native error');
    }
    return stored;
  }

  @override
  Future<bool> saveWhitelist(WhitelistConfigModel config) async {
    saveCallCount++;
    if (shouldFailSave) return false;
    stored = config;
    return true;
  }
}

void main() {
  late _FakeWhitelistRepository repository;
  late WhitelistBloc bloc;

  setUp(() {
    repository = _FakeWhitelistRepository();
    bloc = WhitelistBloc(repository: repository);
  });

  tearDown(() {
    bloc.close();
  });

  group('WhitelistStarted', () {
    test('loads config from native', () async {
      repository.stored = const WhitelistConfigModel(
        mode: WhitelistMode.allAddresses,
        entries: [WhitelistEntryModel(address: 'VCB', allowOtp: true)],
      );

      bloc.add(const WhitelistStarted());
      await bloc.close();

      expect(bloc.state.isLoading, isFalse);
      expect(bloc.state.config.mode, WhitelistMode.allAddresses);
      expect(bloc.state.config.entries.first.address, 'VCB');
    });

    test('emits error when load fails', () async {
      repository.shouldFailLoad = true;

      bloc.add(const WhitelistStarted());
      await bloc.close();

      expect(bloc.state.errorMessage, isNotNull);
      expect(bloc.state.config, const WhitelistConfigModel());
    });

    test('empty explicit config marks blocksEverything', () async {
      bloc.add(const WhitelistStarted());
      await bloc.close();

      expect(bloc.state.blocksEverything, isTrue);
    });
  });

  group('WhitelistEntryAdded', () {
    test('adds entry with allowOtp default false and persists', () async {
      bloc.add(const WhitelistStarted());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const WhitelistEntryAdded(address: 'VCB'));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.config.entries.length, 1);
      expect(bloc.state.config.entries.first.allowOtp, isFalse);
      expect(repository.saveCallCount, 1);
      expect(repository.stored.entries.first.address, 'VCB');
    });

    test('rejects blank address without persisting', () async {
      bloc.add(const WhitelistStarted());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const WhitelistEntryAdded(address: '   '));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.errorMessage, isNotNull);
      expect(repository.saveCallCount, 0);
    });

    test('rejects duplicate address case-insensitively', () async {
      bloc.add(const WhitelistStarted());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const WhitelistEntryAdded(address: 'VCB'));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const WhitelistEntryAdded(address: 'vcb'));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.config.entries.length, 1);
      expect(bloc.state.errorMessage, contains('đã có trong danh sách'));
      expect(repository.saveCallCount, 1);
    });
  });

  group('WhitelistAllowOtpToggled', () {
    test('toggles allowOtp on matching entry only', () async {
      bloc.add(const WhitelistStarted());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const WhitelistEntryAdded(address: 'VCB'));
      bloc.add(const WhitelistEntryAdded(address: 'MOMO'));
      await Future<void>.delayed(Duration.zero);
      bloc.add(WhitelistAllowOtpToggled(bloc.state.config.entries.first));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.config.entries[0].allowOtp, isTrue);
      expect(bloc.state.config.entries[1].allowOtp, isFalse);
      expect(repository.saveCallCount, 3);
    });
  });

  group('WhitelistEntryRemoved', () {
    test('removes matching entry', () async {
      bloc.add(const WhitelistStarted());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const WhitelistEntryAdded(address: 'VCB'));
      await Future<void>.delayed(Duration.zero);
      final entry = bloc.state.config.entries.first;
      bloc.add(WhitelistEntryRemoved(entry));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.config.entries, isEmpty);
      expect(bloc.state.blocksEverything, isTrue);
    });
  });

  group('WhitelistModeChanged', () {
    test('switches mode and persists', () async {
      bloc.add(const WhitelistStarted());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const WhitelistModeChanged(WhitelistMode.allAddresses));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.config.mode, WhitelistMode.allAddresses);
      expect(repository.stored.mode, WhitelistMode.allAddresses);
    });

    test('save failure keeps old config and emits error', () async {
      bloc.add(const WhitelistStarted());
      await Future<void>.delayed(Duration.zero);
      repository.shouldFailSave = true;
      bloc.add(const WhitelistEntryAdded(address: 'VCB'));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.config.entries, isEmpty);
      expect(bloc.state.errorMessage, isNotNull);
    });
  });
}

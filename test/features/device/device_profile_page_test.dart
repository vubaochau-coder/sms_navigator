import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/repositories/channel_repository.dart';
import 'package:sms_navigator/core/repositories/device_setup_repository.dart';
import 'package:sms_navigator/core/services/device_storage_service.dart';
import 'package:sms_navigator/core/storage/local_storage_service.dart';
import 'package:sms_navigator/core/theme/theme_cubit.dart';
import 'package:sms_navigator/features/device/bloc/device_profile_cubit.dart';
import 'package:sms_navigator/features/device/bloc/device_setup_bloc.dart';
import 'package:sms_navigator/features/device/bloc/device_setup_event.dart';
import 'package:sms_navigator/features/device/device_profile_page.dart';
import 'package:sms_navigator/features/device/views/device_health_section.dart';
import 'package:sms_navigator/features/device/views/device_info_card.dart';
import 'package:sms_navigator/features/device/views/device_preferences_section.dart';
import 'package:sms_navigator/l10n/app_localizations.dart';

class _FakeDeviceStorageService implements DeviceStorageService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<String?> getDeviceId() async => 'dev_abc123xyz456';

  @override
  Future<String?> getDeviceName() async => 'Pixel 8 Pro';
}

class _FakeChannelRepository implements ChannelRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeDeviceSetupRepository implements DeviceSetupRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<bool> isSmsPermissionGranted() async => true;

  @override
  Future<bool> isSmsPermissionPermanentlyDenied() async => false;

  @override
  Future<bool> isBatteryOptimizationIgnored() async => true;

  @override
  Future<bool> isAutostartAcknowledged() async => true;

  @override
  Future<Map<String, dynamic>> getAggressiveRomInfo() async => {
        'isAggressive': false,
        'oem': 'google',
      };

  @override
  Future<bool> shouldPromptSmsPermission() async => false;
}

class _FakeLocalStorageService implements LocalStorageService {
  final Map<String, dynamic> _data = {};

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  String? getString(String key) => _data[key] as String?;

  @override
  Future<bool> setString(String key, String value) async {
    _data[key] = value;
    return true;
  }
}

void main() {
  late _FakeDeviceStorageService storage;
  late _FakeChannelRepository channelRepo;
  late _FakeDeviceSetupRepository setupRepo;
  late _FakeLocalStorageService localStore;
  late DeviceProfileCubit profileCubit;
  late DeviceSetupBloc setupBloc;
  late ThemeCubit themeCubit;

  setUp(() {
    storage = _FakeDeviceStorageService();
    channelRepo = _FakeChannelRepository();
    setupRepo = _FakeDeviceSetupRepository();
    localStore = _FakeLocalStorageService();

    profileCubit = DeviceProfileCubit(
      deviceStorage: storage,
      channelRepository: channelRepo,
    );
    setupBloc = DeviceSetupBloc(repository: setupRepo)
      ..add(const DeviceSetupStarted());
    themeCubit = ThemeCubit(localStorage: localStore);
  });

  tearDown(() {
    profileCubit.close();
    setupBloc.close();
    themeCubit.close();
  });

  Widget buildTestWidget() {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: profileCubit),
        BlocProvider.value(value: setupBloc),
        BlocProvider.value(value: themeCubit),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: DeviceProfilePage(),
      ),
    );
  }

  testWidgets('DeviceProfilePage renders all 3 sections and correct title', (tester) async {
    await profileCubit.loadDeviceProfile();
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Check AppBar title
    expect(find.text('Thông tin & Thiết lập thiết bị'), findsOneWidget);

    // Check DeviceInfoCard section
    expect(find.byType(DeviceInfoCard), findsOneWidget);
    expect(find.text('Pixel 8 Pro'), findsOneWidget);

    // Check DeviceHealthSection
    expect(find.byType(DeviceHealthSection), findsOneWidget);
    expect(find.text('TÌNH TRẠNG THIẾT BỊ'), findsOneWidget);

    // Check DevicePreferencesSection
    expect(find.byType(DevicePreferencesSection), findsOneWidget);
    expect(find.text('CÀI ĐẶT & TÙY CHỌN'), findsOneWidget);
    expect(find.text('Bộ lọc SMS (Whitelist)'), findsOneWidget);
    expect(find.text('Xóa dữ liệu thiết bị'), findsOneWidget);
  });
}

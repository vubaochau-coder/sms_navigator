import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/models/channel_model.dart';
import 'package:sms_navigator/core/repositories/channel_repository.dart';
import 'package:sms_navigator/core/repositories/device_setup_repository.dart';
import 'package:sms_navigator/core/services/device_storage_service.dart';
import 'package:sms_navigator/features/channel/channel_page.dart';
import 'package:sms_navigator/features/channel/views/channel_list_view.dart';
import 'package:sms_navigator/features/device/bloc/device_profile_cubit.dart';
import 'package:sms_navigator/features/device/bloc/device_setup_bloc.dart';
import 'package:sms_navigator/l10n/app_localizations.dart';

class _FakeChannelRepository implements ChannelRepository {
  List<ChannelModel> channels = [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<ChannelModel>> listChannels() async => channels;
}

class _FakeDeviceStorageService implements DeviceStorageService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<String?> getDeviceId() async => 'dev_test';

  @override
  Future<String?> getDeviceName() async => 'Thiết bị test';
}

class _FakeDeviceSetupRepository implements DeviceSetupRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<bool> isSmsPermissionGranted() async => true;

  @override
  Future<bool> isBatteryOptimizationIgnored() async => true;
}

void main() {
  late _FakeChannelRepository repository;

  setUp(() {
    repository = _FakeChannelRepository();
  });

  Widget buildTestWidget() {
    return RepositoryProvider<ChannelRepository>.value(
      value: repository,
      child: MultiBlocProvider(
        providers: [
          BlocProvider<DeviceProfileCubit>(
            create: (_) => DeviceProfileCubit(
              deviceStorage: _FakeDeviceStorageService(),
              channelRepository: repository,
            ),
          ),
          BlocProvider<DeviceSetupBloc>(
            create: (_) => DeviceSetupBloc(
              repository: _FakeDeviceSetupRepository(),
            ),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ChannelPage(),
        ),
      ),
    );
  }

  testWidgets('ChannelPage renders DefaultTabController with 2 tabs and empty state', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Verify DefaultTabController exists with 2 tabs
    expect(find.byType(DefaultTabController), findsOneWidget);
    expect(find.text('Kênh của bạn'), findsOneWidget);
    expect(find.text('Kênh bạn tham gia'), findsOneWidget);

    // Empty state should be visible for owned tab
    expect(find.byType(ChannelEmptyPane), findsOneWidget);
    expect(find.byIcon(Icons.hub_outlined), findsOneWidget);
    expect(
      find.text('Bạn chưa tạo kênh nào.\nNhấn nút "Tạo kênh" bên dưới.'),
      findsOneWidget,
    );

    // Switch to Joined tab
    await tester.tap(find.text('Kênh bạn tham gia'));
    await tester.pumpAndSettle();

    // Empty state for joined tab
    expect(
      find.text('Bạn chưa tham gia kênh nào.\nQuét mã QR mời để tham gia kênh.'),
      findsOneWidget,
    );
  });

  testWidgets('ChannelPage displays channels under correct tabs', (
    tester,
  ) async {
    repository.channels = const [
      ChannelModel(
        channelId: 'owned_1',
        name: 'Kênh Gia Đình (Owner)',
        role: ChannelRole.owner,
        memberCount: 3,
      ),
      ChannelModel(
        channelId: 'joined_1',
        name: 'Kênh Công Ty (Member)',
        role: ChannelRole.member,
        memberCount: 10,
      ),
    ];

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // First tab (Owned): should show owned channel, not joined
    expect(find.text('Kênh Gia Đình (Owner)'), findsOneWidget);
    expect(find.text('Kênh Công Ty (Member)'), findsNothing);

    // Switch to second tab (Joined)
    await tester.tap(find.text('Kênh bạn tham gia'));
    await tester.pumpAndSettle();

    expect(find.text('Kênh Công Ty (Member)'), findsOneWidget);
  });

  testWidgets('FAB has bottom padding offset to prevent crowding bottom navigation bar', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    final fabFinder = find.byType(FloatingActionButton);
    expect(fabFinder, findsOneWidget);

    // FAB is wrapped in a Padding with bottom offset
    final paddingFinder = find.ancestor(
      of: fabFinder,
      matching: find.byType(Padding),
    );
    expect(paddingFinder, findsWidgets);

    final paddingWidget = tester.widget<Padding>(paddingFinder.first);
    final insets = paddingWidget.padding as EdgeInsets;
    expect(insets.bottom, greaterThanOrEqualTo(16.0));
  });
}

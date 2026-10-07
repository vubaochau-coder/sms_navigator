import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/models/pairing_request_model.dart';
import 'package:sms_navigator/core/repositories/channel_repository.dart';
import 'package:sms_navigator/core/repositories/join_channel_repository.dart';
import 'package:sms_navigator/features/channel/bloc/channel_bloc.dart';
import 'package:sms_navigator/features/channel/views/pending_join_request_card.dart';
import 'package:sms_navigator/l10n/app_localizations.dart';

class _FakeChannelRepository implements ChannelRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeJoinChannelRepository implements JoinChannelRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('PendingJoinRequestCard renders owner device name and timestamp', (tester) async {
    const request = PairingRequestModel(
      requestId: 'req_123',
      channelId: 'ch_456',
      channelName: 'Kênh Gia Đình',
      ownerDeviceName: 'Pixel 8 của Bố',
      createdAt: '2026-10-06T15:30:00.000Z',
    );

    await tester.pumpWidget(
      BlocProvider<ChannelBloc>(
        create: (_) => ChannelBloc(
          repository: _FakeChannelRepository(),
          joinRepository: _FakeJoinChannelRepository(),
        ),
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: PendingJoinRequestCard(request: request),
          ),
        ),
      ),
    );

    expect(find.text('Kênh Gia Đình'), findsOneWidget);
    expect(find.text('Chủ kênh: Pixel 8 của Bố'), findsOneWidget);
    expect(find.text(request.formattedCreatedAt), findsOneWidget);

    final cancelButton = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
    expect(cancelButton.style?.visualDensity, VisualDensity.compact);
    expect(find.text('Hủy yêu cầu'), findsOneWidget);
  });
}

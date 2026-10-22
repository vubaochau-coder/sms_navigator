import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/models/vault_fallback_report.dart';
import 'package:sms_navigator/core/services/crashlytics_service.dart';
import 'package:sms_navigator/core/services/native_relay_service.dart';
import 'package:sms_navigator/core/usecases/report_vault_fallback_use_case.dart';

class _Native implements NativeRelayService {
  VaultFallbackReport? report;

  @override
  Future<VaultFallbackReport?> takeVaultFallbackReport() async {
    final pending = report;
    report = null;
    return pending;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Crashlytics implements CrashlyticsService {
  final List<Object> errors = [];

  @override
  Future<void> recordError(
    dynamic error,
    StackTrace? stack, {
    dynamic reason,
    Iterable<Object> information = const [],
    bool fatal = false,
  }) async => errors.add(error as Object);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _Native native;
  late _Crashlytics crashlytics;
  late List<String> warnings;
  late ReportVaultFallbackUseCase useCase;

  setUp(() {
    native = _Native();
    crashlytics = _Crashlytics();
    warnings = [];
    useCase = ReportVaultFallbackUseCase(nativeRelay: native, crashlytics: crashlytics, warn: warnings.add);
  });

  test('nothing to report → no Crashlytics event, no warning', () async {
    expect(await useCase(), isNull);
    expect(crashlytics.errors, isEmpty);
    expect(warnings, isEmpty);
  });

  test('a pending report goes to Crashlytics as non-fatal and warns the user once', () async {
    native.report = const VaultFallbackReport(count: 3, site: 'relay_store', error: 'KeyStoreException: boom');

    final report = await useCase();
    expect(report?.count, 3);
    expect(crashlytics.errors.single, isA<VaultFallbackError>());
    expect(crashlytics.errors.single.toString(), contains('relay_store'));
    expect(warnings, hasLength(1));

    // Native cleared it: the next launch is quiet
    expect(await useCase(), isNull);
    expect(warnings, hasLength(1));
  });

  test('VaultFallbackReport.fromMap ignores empty / zero-count maps', () {
    expect(VaultFallbackReport.fromMap(null), isNull);
    expect(VaultFallbackReport.fromMap({'count': 0}), isNull);
    final parsed = VaultFallbackReport.fromMap({'count': 2, 'site': 'device_token', 'error': 'x', 'at': 1000});
    expect(parsed, VaultFallbackReport(count: 2, site: 'device_token', error: 'x', at: DateTime.fromMillisecondsSinceEpoch(1000)));
  });
}

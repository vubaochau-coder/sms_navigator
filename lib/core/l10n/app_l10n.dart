import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';

/// Truy cập l10n không cần [BuildContext] — cho BLoC, service, callback và
/// background handler (FCM). App chỉ hỗ trợ tiếng Việt nên locale cố định.
///
/// Trong widget, ưu tiên `context.l10n` (extension trong `context_extensions.dart`).
abstract final class AppL10n {
  static AppLocalizations? _current;

  static AppLocalizations get current =>
      _current ??= lookupAppLocalizations(const Locale('vi'));
}

import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

extension ContextExtensions on BuildContext {
  /// Truy cập nhanh AppLocalizations (không null).
  AppLocalizations get l10n => AppLocalizations.of(this)!;

  /// Truy cập Theme hiện tại.
  ThemeData get theme => Theme.of(this);

  /// Truy cập ColorScheme hiện tại.
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
}

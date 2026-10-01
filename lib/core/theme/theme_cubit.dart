import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../storage/local_storage_service.dart';
import '../storage/storage_keys.dart';

/// Quản lý chế độ giao diện Light/Dark/System, lưu lựa chọn vào Local Storage.
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit({required this.localStorage})
    : super(_modeFromString(localStorage.getString(StorageKeys.themeMode)));

  final LocalStorageService localStorage;

  static const String _keyLight = 'light';
  static const String _keyDark = 'dark';
  static const String _keySystem = 'system';

  /// Chuyển đổi Light/Dark. Với trạng thái System, chọn chế độ ngược
  /// với độ sáng hiện tại của hệ điều hành.
  Future<void> toggleTheme() async {
    final next = _nextThemeMode();
    emit(next);
    await localStorage.setString(StorageKeys.themeMode, _stringFromMode(next));
  }

  ThemeMode _nextThemeMode() {
    switch (state) {
      case ThemeMode.light:
        return ThemeMode.dark;
      case ThemeMode.dark:
        return ThemeMode.light;
      case ThemeMode.system:
        final isDarkNow =
            WidgetsBinding.instance.platformDispatcher.platformBrightness ==
            Brightness.dark;
        return isDarkNow ? ThemeMode.light : ThemeMode.dark;
    }
  }

  static ThemeMode _modeFromString(String? value) {
    switch (value) {
      case _keyLight:
        return ThemeMode.light;
      case _keyDark:
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static String _stringFromMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return _keyLight;
      case ThemeMode.dark:
        return _keyDark;
      case ThemeMode.system:
        return _keySystem;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Quản lý chế độ giao diện Light/Dark/System, lưu lựa chọn vào SharedPreferences.
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit() : super(ThemeMode.system) {
    _loadSavedThemeMode();
  }

  static const String _prefKey = 'app_theme_mode';
  static const String _keyLight = 'light';
  static const String _keyDark = 'dark';
  static const String _keySystem = 'system';

  Future<void> _loadSavedThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    emit(_modeFromString(prefs.getString(_prefKey)));
  }

  /// Chuyển đổi Light/Dark. Với trạng thái System, chọn chế độ ngược
  /// với độ sáng hiện tại của hệ điều hành.
  Future<void> toggleTheme() async {
    final next = _nextThemeMode();
    emit(next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, _stringFromMode(next));
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

import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  static const double radiusL = 20;
  static const double radiusM = 16;

  static const _SoftPalette _light = _SoftPalette(
    primary: AppColors.primary,
    primarySoft: AppColors.primarySoft,
    secondary: AppColors.secondary,
    secondarySoft: AppColors.secondarySoft,
    background: AppColors.background,
    surface: AppColors.surface,
    surfaceVariant: AppColors.surfaceVariant,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textMuted: AppColors.textMuted,
    success: AppColors.success,
    warning: AppColors.warning,
    error: AppColors.error,
    border: AppColors.border,
    divider: AppColors.divider,
    shadow: AppColors.shadow,
    brightness: Brightness.light,
  );

  static const _SoftPalette _dark = _SoftPalette(
    primary: AppDarkColors.primary,
    primarySoft: AppDarkColors.primarySoft,
    secondary: AppDarkColors.secondary,
    secondarySoft: AppDarkColors.secondarySoft,
    background: AppDarkColors.background,
    surface: AppDarkColors.surface,
    surfaceVariant: AppDarkColors.surfaceVariant,
    textPrimary: AppDarkColors.textPrimary,
    textSecondary: AppDarkColors.textSecondary,
    textMuted: AppDarkColors.textMuted,
    success: AppDarkColors.success,
    warning: AppDarkColors.warning,
    error: AppDarkColors.error,
    border: AppDarkColors.border,
    divider: AppDarkColors.divider,
    shadow: AppDarkColors.shadow,
    brightness: Brightness.dark,
  );

  static ThemeData get lightTheme => _buildTheme(_light);

  static ThemeData get darkTheme => _buildTheme(_dark);

  static ThemeData _buildTheme(_SoftPalette c) {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: c.primary,
          brightness: c.brightness,
        ).copyWith(
          primary: c.primary,
          secondary: c.secondary,
          surface: c.surface,
          surfaceContainerLowest: c.surface,
          surfaceContainerLow: c.surface,
          surfaceContainer: c.surfaceVariant,
          error: c.error,
          outline: c.border,
          outlineVariant: c.divider,
          onPrimary: Colors.white,
          onSurface: c.textPrimary,
          onSurfaceVariant: c.textSecondary,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: c.brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: c.background,
      splashFactory: InkRipple.splashFactory,

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: c.textPrimary),
        actionsIconTheme: IconThemeData(color: c.textPrimary),
        titleTextStyle: TextStyle(
          color: c.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),

      // Card — bo góc mềm, bóng tinh tế
      cardTheme: CardThemeData(
        color: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        shadowColor: c.shadow,
        margin: const EdgeInsets.all(0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusL),
          side: BorderSide(color: c.border),
        ),
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: c.primary.withValues(alpha: 0.4),
          elevation: 3,
          shadowColor: c.shadow,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusM),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.primary,
          side: BorderSide(color: c.primary.withValues(alpha: 0.5), width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusM),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      // Input
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        hintStyle: TextStyle(color: c.textMuted, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: BorderSide(color: c.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: BorderSide(color: c.error, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: BorderSide(color: c.error, width: 1.6),
        ),
      ),

      // Dialog & Bottom Sheet
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusL),
        ),
        titleTextStyle: TextStyle(
          color: c.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusL)),
        ),
        showDragHandle: true,
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.textPrimary,
        contentTextStyle: TextStyle(color: c.background, fontSize: 14),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),

      // FloatingActionButton
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: c.primary,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusM),
        ),
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: c.primarySoft,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        labelStyle: TextStyle(color: c.primary, fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      ),

      // Divider
      dividerTheme: DividerThemeData(color: c.divider, thickness: 1, space: 1),

      // ListTile
      listTileTheme: ListTileThemeData(
        iconColor: c.textSecondary,
        titleTextStyle: TextStyle(
          color: c.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        subtitleTextStyle: TextStyle(color: c.textSecondary, fontSize: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusM),
        ),
      ),

      textTheme: TextTheme(
        headlineSmall: TextStyle(
          color: c.textPrimary,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          color: c.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: TextStyle(color: c.textPrimary),
        bodyMedium: TextStyle(color: c.textPrimary),
        bodySmall: TextStyle(color: c.textSecondary),
      ),
    );
  }
}

/// Bộ màu đã chuẩn hóa dùng chung cho light & dark theme.
class _SoftPalette {
  const _SoftPalette({
    required this.primary,
    required this.primarySoft,
    required this.secondary,
    required this.secondarySoft,
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.success,
    required this.warning,
    required this.error,
    required this.border,
    required this.divider,
    required this.shadow,
    required this.brightness,
  });

  final Color primary;
  final Color primarySoft;
  final Color secondary;
  final Color secondarySoft;
  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color success;
  final Color warning;
  final Color error;
  final Color border;
  final Color divider;
  final Color shadow;
  final Brightness brightness;
}

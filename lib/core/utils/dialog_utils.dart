import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../navigation/app_navigator.dart';

/// Tiện ích hiển thị Dialog / Alert thống nhất cho toàn bộ dự án
class DialogUtils {
  DialogUtils._();

  /// Navigator key toàn cục lấy từ Single Source of Truth [AppNavigator.key].
  static GlobalKey<NavigatorState> get navigatorKey => AppNavigator.key;

  // ==========================================
  // HẰNG SỐ GIAO DIỆN CHUẨN (UI TOKENS)
  // ==========================================
  static const double borderRadiusValue = 16.0;
  static const BorderRadius borderRadius = BorderRadius.all(
    Radius.circular(borderRadiusValue),
  );
  static const double buttonRadiusValue = 8.0;
  static const BorderRadius buttonBorderRadius = BorderRadius.all(
    Radius.circular(buttonRadiusValue),
  );

  static const double iconSize = 24.0;
  static const double iconSpacing = 8.0;
  static const double titleFontSize = 17.0;
  static const double messageFontSize = 14.0;
  static const double messageLineHeight = 1.4;

  /// Inset padding chuẩn: khoảng cách tới các mép màn hình là 12px (trái phải)
  static const EdgeInsets insetPadding = EdgeInsets.symmetric(
    horizontal: 12.0,
    vertical: 24.0,
  );

  /// Padding nội bộ chuẩn của AlertDialog: giảm bớt khoảng trống thừa giữa Title, Content và Actions
  static const EdgeInsets defaultTitlePadding =
      EdgeInsets.fromLTRB(20.0, 18.0, 20.0, 6.0);
  static const EdgeInsets defaultContentPadding =
      EdgeInsets.fromLTRB(20.0, 6.0, 20.0, 14.0);
  static const EdgeInsets defaultActionsPadding =
      EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 12.0);

  static const String defaultConfirmText = 'Xác nhận';
  static const String defaultCancelText = 'Hủy bỏ';
  static const String defaultCloseText = 'Đóng';

  /// Helper lấy BuildContext an toàn từ tham số hoặc [AppNavigator.currentContext]
  static BuildContext _resolveContext(BuildContext? context) {
    final ctx = context ?? AppNavigator.currentContext;
    if (ctx == null) {
      throw StateError(
        'Không tìm thấy BuildContext để hiển thị Dialog. Hãy truyền context hoặc cài đặt navigatorKey trong MaterialApp.',
      );
    }
    return ctx;
  }

  static OverlayEntry? _loadingOverlayEntry;

  /// Kiểm tra xem lớp phủ loading toàn màn hình có đang hiển thị hay không
  static bool get isLoading => _loadingOverlayEntry != null;

  /// Hiển thị lớp phủ loading toàn màn hình (không bắt buộc context).
  ///
  /// - Sử dụng [OverlayEntry] gắn trực tiếp lên root Overlay của ứng dụng qua [AppNavigator.overlay].
  /// - Tự động chặn mọi thao tác chạm/vuốt (ModalBarrier).
  /// - An toàn khi gọi từ BLoC, Cubit hoặc các tác vụ background.
  /// - Nếu không tìm thấy Overlay (VD: trong unit test không mount UI), hàm sẽ thoát an toàn.
  static void showLoading({
    BuildContext? context,
    String? message,
  }) {
    if (_loadingOverlayEntry != null) return;

    final overlayState = context != null
        ? Overlay.maybeOf(context) ?? AppNavigator.overlay
        : AppNavigator.overlay;

    if (overlayState == null) {
      debugPrint('DialogUtils.showLoading: Không tìm thấy Overlay để hiển thị loading.');
      return;
    }

    final entry = OverlayEntry(
      builder: (entryContext) {
        final theme = Theme.of(entryContext);
        final colorScheme = theme.colorScheme;

        return PopScope(
          canPop: false,
          child: Material(
            type: MaterialType.transparency,
            child: Stack(
              children: [
                // Lớp phủ mờ chặn mọi tương tác
                ModalBarrier(
                  dismissible: false,
                  color: Colors.black.withValues(alpha: 0.35),
                ),
                // Hộp hiển thị Spinner & Message ở trung tâm
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: borderRadius,
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 16,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          strokeWidth: 3.5,
                          color: colorScheme.primary,
                        ),
                        if (message != null && message.trim().isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            message.trim(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    _loadingOverlayEntry = entry;
    overlayState.insert(entry);
  }

  /// Đóng lớp phủ loading toàn màn hình (không cần context).
  static void closeLoading() {
    _loadingOverlayEntry?.remove();
    _loadingOverlayEntry = null;
  }

  /// Hiển thị container Dialog chuẩn dự án cho nội dung tùy biến (custom content).
  ///
  /// [child]: Widget nội dung bên trong dialog (tham số bắt buộc).
  /// Cung cấp sẵn khung chuẩn: bo góc [borderRadius], insetPadding 12px trái phải,
  /// màu nền [ColorScheme.surface], clip antiAlias.
  static Future<T?> showBaseForm<T>({
    required Widget child,
    BuildContext? context,
    bool barrierDismissible = true,
    Color? barrierColor,
    EdgeInsets? customInsetPadding,
    bool useSafeArea = true,
  }) {
    final ctx = _resolveContext(context);
    final padding = customInsetPadding ?? insetPadding;
    return showDialog<T>(
      context: ctx,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      useSafeArea: useSafeArea,
      builder: (dialogContext) {
        final screenHeight = MediaQuery.sizeOf(dialogContext).height;
        final maxHeight = screenHeight - padding.vertical;
        return Dialog(
          backgroundColor: Theme.of(dialogContext).colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          shape: const RoundedRectangleBorder(borderRadius: borderRadius),
          insetPadding: padding,
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: 280.0,
              maxWidth: 560.0,
              maxHeight: maxHeight,
            ),
            child: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }

  /// Hiển thị Dialog tùy chỉnh chuẩn form DialogUtils với title, content widget, và danh sách actions.
  /// Khoảng cách tới các mép màn hình trái phải chuẩn 12px.
  static Future<T?> showCustomFormDialog<T>({
    BuildContext? context,
    required String title,
    required Widget content,
    List<Widget>? actions,
    IconData? icon,
    bool barrierDismissible = true,
    EdgeInsets? customInsetPadding,
    EdgeInsets? titlePadding,
    EdgeInsets? contentPadding,
    EdgeInsets? actionsPadding,
  }) {
    final ctx = _resolveContext(context);
    return showDialog<T>(
      context: ctx,
      barrierDismissible: barrierDismissible,
      builder: (dialogContext) {
        return AlertDialog(
          shape: const RoundedRectangleBorder(borderRadius: borderRadius),
          insetPadding: customInsetPadding ?? insetPadding,
          titlePadding: titlePadding ?? defaultTitlePadding,
          contentPadding: contentPadding ?? defaultContentPadding,
          actionsPadding: actionsPadding ?? defaultActionsPadding,
          title: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: AppColors.primary, size: iconSize),
                const SizedBox(width: iconSpacing),
              ],
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: content,
            ),
          ),
          actions: actions,
        );
      },
    );
  }

  /// Hiển thị Dialog nhập liệu văn bản (TextField) chuẩn form DialogUtils.
  /// Áp dụng đầy đủ chuẩn form: 12px insetPadding, padding nội bộ compact, nút tối đa 48px.
  static Future<String?> showInputDialog({
    BuildContext? context,
    required String title,
    String? hintText,
    String? labelText,
    String? initialValue,
    IconData? icon,
    int? maxLength,
    String confirmText = defaultConfirmText,
    String cancelText = defaultCancelText,
    EdgeInsets? customInsetPadding,
  }) {
    final ctx = _resolveContext(context);
    final controller = TextEditingController(text: initialValue);

    return showDialog<String>(
      context: ctx,
      builder: (dialogContext) {
        return AlertDialog(
          shape: const RoundedRectangleBorder(borderRadius: borderRadius),
          insetPadding: customInsetPadding ?? insetPadding,
          titlePadding: defaultTitlePadding,
          contentPadding: defaultContentPadding,
          actionsPadding: defaultActionsPadding,
          title: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: AppColors.primary, size: iconSize),
                const SizedBox(width: iconSpacing),
              ],
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: TextField(
                controller: controller,
                autofocus: true,
                maxLength: maxLength,
                decoration: InputDecoration(
                  labelText: labelText,
                  hintText: hintText,
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (value) {
                  final trimmed = value.trim();
                  if (trimmed.isNotEmpty) {
                    Navigator.of(dialogContext).pop(trimmed);
                  }
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                maximumSize: const Size.fromHeight(48),
                minimumSize: const Size(0, 40),
                shape: const RoundedRectangleBorder(
                  borderRadius: buttonBorderRadius,
                ),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(null),
              child: Text(
                cancelText,
                style: TextStyle(
                  color: Theme.of(dialogContext)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                maximumSize: const Size.fromHeight(48),
                minimumSize: const Size(0, 40),
                shape: const RoundedRectangleBorder(
                  borderRadius: buttonBorderRadius,
                ),
                elevation: 0,
              ),
              onPressed: () {
                final trimmed = controller.text.trim();
                if (trimmed.isNotEmpty) {
                  Navigator.of(dialogContext).pop(trimmed);
                }
              },
              child: Text(
                confirmText,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Hộp thoại thông báo (chỉ có 1 nút để đóng).
  ///
  /// - [isMandatory]: Nếu true, người dùng bắt buộc phải nhấn nút để đóng
  ///   (không thể tap ra ngoài vùng dialog hoặc bấm nút Back để đóng).
  static Future<bool> showInfoDialog({
    BuildContext? context,
    required String title,
    required String message,
    String buttonText = defaultCloseText,
    IconData? icon,
    bool isMandatory = false,
    EdgeInsets? customInsetPadding,
  }) async {
    final ctx = _resolveContext(context);

    final result = await showDialog<bool>(
      context: ctx,
      barrierDismissible: !isMandatory,
      builder: (dialogContext) {
        return PopScope(
          canPop: !isMandatory,
          child: AlertDialog(
            shape: const RoundedRectangleBorder(borderRadius: borderRadius),
            insetPadding: customInsetPadding ?? insetPadding,
            titlePadding: defaultTitlePadding,
            contentPadding: defaultContentPadding,
            actionsPadding: defaultActionsPadding,
            title: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: AppColors.primary, size: iconSize),
                  const SizedBox(width: iconSpacing),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: messageFontSize,
                    color: Theme.of(
                      dialogContext,
                    ).colorScheme.onSurface.withValues(alpha: 0.8),
                    height: messageLineHeight,
                  ),
                ),
              ),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  maximumSize: const Size.fromHeight(48),
                  minimumSize: const Size(0, 40),
                  shape: const RoundedRectangleBorder(
                    borderRadius: buttonBorderRadius,
                  ),
                  elevation: 0,
                ),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(
                  buttonText,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        );
      },
    );

    return result ?? false;
  }

  /// Hộp thoại 2 lựa chọn (Negative & Positive).
  ///
  /// - Trả về `true` khi chọn nút Positive.
  /// - Trả về `false` khi chọn nút Negative.
  /// - Trả về `null` khi bị đóng ngoài ý muốn (tap ra ngoài hoặc bấm back) nếu [isMandatory] = false.
  /// - [swapButtonPositions]: Nếu true, hoán đổi vị trí của Positive (trái) và Negative (phải).
  /// - [isMandatory]: Nếu true, bắt buộc người dùng phải chọn 1 trong 2 nút (không thể trả về null).
  static Future<bool?> showTwoOptionsDialog({
    BuildContext? context,
    required String title,
    required String message,
    String positiveText = defaultConfirmText,
    String negativeText = defaultCancelText,
    bool isPositiveDestructive = false,
    bool swapButtonPositions = false,
    bool isMandatory = false,
    IconData? icon,
    EdgeInsets? customInsetPadding,
  }) async {
    final ctx = _resolveContext(context);

    final result = await showDialog<bool?>(
      context: ctx,
      barrierDismissible: !isMandatory,
      builder: (dialogContext) {
        final negativeButton = TextButton(
          style: TextButton.styleFrom(
            maximumSize: const Size.fromHeight(48),
            minimumSize: const Size(0, 40),
          ),
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(
            negativeText,
            style: TextStyle(
              color: Theme.of(
                dialogContext,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w600,
            ),
          ),
        );

        final positiveButton = ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isPositiveDestructive
                ? AppColors.error
                : AppColors.primary,
            foregroundColor: Colors.white,
            maximumSize: const Size.fromHeight(48),
            minimumSize: const Size(0, 40),
            shape: const RoundedRectangleBorder(
              borderRadius: buttonBorderRadius,
            ),
            elevation: 0,
          ),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(
            positiveText,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        );

        final actions = swapButtonPositions
            ? [positiveButton, negativeButton]
            : [negativeButton, positiveButton];

        return PopScope(
          canPop: !isMandatory,
          child: AlertDialog(
            shape: const RoundedRectangleBorder(borderRadius: borderRadius),
            insetPadding: customInsetPadding ?? insetPadding,
            titlePadding: defaultTitlePadding,
            contentPadding: defaultContentPadding,
            actionsPadding: defaultActionsPadding,
            title: Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    color: isPositiveDestructive
                        ? AppColors.error
                        : AppColors.primary,
                    size: iconSize,
                  ),
                  const SizedBox(width: iconSpacing),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: messageFontSize,
                    color: Theme.of(
                      dialogContext,
                    ).colorScheme.onSurface.withValues(alpha: 0.8),
                    height: messageLineHeight,
                  ),
                ),
              ),
            ),
            actions: actions,
          ),
        );
      },
    );

    return result;
  }

  /// Hộp thoại xác nhận hành động (VD: Hủy kết nối, Xóa dữ liệu).
  ///
  /// Giữ tương thích ngược với các caller hiện có, ủy quyền xử lý cho [showTwoOptionsDialog].
  static Future<bool> showConfirmDialog({
    BuildContext? context,
    required String title,
    required String message,
    String confirmText = defaultConfirmText,
    String cancelText = defaultCancelText,
    bool isDestructive = false,
    IconData? icon,
    EdgeInsets? customInsetPadding,
  }) async {
    final result = await showTwoOptionsDialog(
      context: context,
      title: title,
      message: message,
      positiveText: confirmText,
      negativeText: cancelText,
      isPositiveDestructive: isDestructive,
      icon: icon,
      customInsetPadding: customInsetPadding,
    );
    return result ?? false;
  }
}

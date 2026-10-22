import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/widgets/app_logo_glyph.dart';

/// Phần hiển thị thương hiệu ứng dụng (Logo Hero có animation pulse, Tên ứng dụng & Phụ đề).
class SplashBrandingView extends StatefulWidget {
  final Animation<double>? scaleAnimation;

  const SplashBrandingView({
    super.key,
    this.scaleAnimation,
  });

  @override
  State<SplashBrandingView> createState() => _SplashBrandingViewState();
}

class _SplashBrandingViewState extends State<SplashBrandingView>
    with SingleTickerProviderStateMixin {
  AnimationController? _internalController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.scaleAnimation != null) {
      _scaleAnimation = widget.scaleAnimation!;
    } else {
      _internalController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1400),
      )..repeat(reverse: true);
      _scaleAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
        CurvedAnimation(parent: _internalController!, curve: Curves.easeInOut),
      );
    }
  }

  @override
  void didUpdateWidget(covariant SplashBrandingView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.scaleAnimation != null) {
      _scaleAnimation = widget.scaleAnimation!;
    }
  }

  @override
  void dispose() {
    _internalController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // App Logo Hero với hiệu ứng pulse
        ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.32),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: AppLogoGlyph(
                size: 64,
                bubbleColor: colorScheme.onPrimary,
                arrowColor: colorScheme.primary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Tên ứng dụng & phụ đề bản địa hóa
        Text(
          AppStrings.appTitle,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.splashSubtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

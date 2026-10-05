import 'package:flutter/material.dart';

import '../../../core/constants/dimens.dart';
import '../../../core/extensions/context_extensions.dart';

/// Top bar with back button and scanner title.
class ScannerTopBar extends StatelessWidget {
  const ScannerTopBar({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: Dimens.screenPadding,
        child: Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                context.l10n.scannerTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

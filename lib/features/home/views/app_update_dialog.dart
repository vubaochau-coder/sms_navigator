import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/models/app_update_info_model.dart';
import '../../../core/repositories/app_update_repository.dart';
import '../../../core/utils/toast_utils.dart';

class AppUpdateDialog extends StatelessWidget {
  final AppUpdateInfoModel updateInfo;
  final AppUpdateRepository updateRepository;

  const AppUpdateDialog({
    super.key,
    required this.updateInfo,
    required this.updateRepository,
  });

  static Future<void> show(
    BuildContext context,
    AppUpdateInfoModel updateInfo,
    AppUpdateRepository updateRepository,
  ) {
    return showDialog<void>(
      context: context,
      barrierDismissible: !updateInfo.isForceUpdate,
      builder: (_) => AppUpdateDialog(
        updateInfo: updateInfo,
        updateRepository: updateRepository,
      ),
    );
  }

  Future<void> _launchDownload(BuildContext context) async {
    final l10n = context.l10n;
    final urlStr = updateInfo.downloadUrl.trim();
    if (urlStr.isEmpty) {
      ToastUtils.showToast(l10n.updateMissingUrlMessage, context: context);
      return;
    }

    final uri = Uri.tryParse(urlStr);
    if (uri == null) {
      ToastUtils.showToast(l10n.updateInvalidUrlMessage, context: context);
      return;
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        ToastUtils.showToast(l10n.updateLaunchErrorMessage, context: context);
      }
    } catch (_) {
      if (context.mounted) {
        ToastUtils.showToast(l10n.updateLaunchErrorMessage, context: context);
      }
    }
  }

  Future<void> _onDismiss(BuildContext context) async {
    await updateRepository.dismissUpdate(updateInfo.latestBuild);
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final displayTitle = updateInfo.title.isNotEmpty
        ? updateInfo.title
        : l10n.updateDialogTitle;

    return PopScope(
      canPop: !updateInfo.isForceUpdate,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 8,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon thông báo cập nhật
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.system_update_rounded,
                  size: 32,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),

              // Tiêu đề
              Text(
                displayTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Chip hiển thị phiên bản
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'v${updateInfo.latestVersion} (Build ${updateInfo.latestBuild})',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Mô tả ngắn / Changelog
              if (updateInfo.description.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 180),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      updateInfo.description,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Ghi chú nếu là cập nhật bắt buộc
              if (updateInfo.isForceUpdate) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: colorScheme.error,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l10n.updateForceNotice,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Các nút hành động
              Row(
                children: [
                  if (!updateInfo.isForceUpdate) ...[
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => _onDismiss(context),
                        child: Text(l10n.updateLaterButton),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: Text(l10n.updateNowButton),
                      onPressed: () => _launchDownload(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

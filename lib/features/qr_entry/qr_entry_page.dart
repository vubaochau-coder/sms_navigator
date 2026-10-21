import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/models/qr_resolution.dart';
import '../../core/repositories/qr_repository.dart';
import '../../core/utils/toast_utils.dart';
import '../channel_join/join_confirm_page.dart';
import 'bloc/qr_entry_cubit.dart';

export 'bloc/qr_entry_cubit.dart';

/// Màn trung gian sau khi nhận một opaque code: kiểm tra mã với server rồi
/// chuyển sang màn nghiệp vụ tương ứng (hiện tại: tham gia kênh).
class QrEntryPage extends StatelessWidget {
  const QrEntryPage({super.key, required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => QrEntryCubit(repository: context.read<QrRepository>())..resolve(code),
      child: QrEntryView(code: code),
    );
  }
}

class QrEntryView extends StatelessWidget {
  const QrEntryView({super.key, required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mã kết nối')),
      body: BlocConsumer<QrEntryCubit, QrEntryState>(
        listener: (context, state) {
          final resolution = state.resolution;
          if (state.phase == QrEntryPhase.resolved && resolution is PairingQrResolution) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) => JoinConfirmPage.fromQr(
                  code: resolution.code,
                  preview: resolution.preview,
                ),
              ),
            );
            return;
          }
          if (state.phase == QrEntryPhase.failed && state.isAlreadyPending) {
            ToastUtils.showInfo(state.errorMessage ?? '');
            Navigator.of(context).pop();
          }
        },
        builder: (context, state) {
          if (state.phase == QrEntryPhase.failed && !state.isAlreadyPending) {
            return QrEntryErrorView(
              message: state.errorMessage ?? 'Không thể kiểm tra mã kết nối.',
              onRetry: () => context.read<QrEntryCubit>().resolve(code),
            );
          }
          return const QrEntryLoadingView();
        },
      ),
    );
  }
}

class QrEntryLoadingView extends StatelessWidget {
  const QrEntryLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Đang kiểm tra mã kết nối…'),
        ],
      ),
    );
  }
}

class QrEntryErrorView extends StatelessWidget {
  const QrEntryErrorView({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline_rounded, size: 48, color: theme.colorScheme.error),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton.tonal(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Quay lại'),
                ),
                const SizedBox(width: 12),
                OutlinedButton(onPressed: onRetry, child: const Text('Thử lại')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

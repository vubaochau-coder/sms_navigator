import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/storage/storage_keys.dart';
import '../../../../core/repositories/impls/whitelist_repository_impl.dart';
import '../../../../core/services/native_relay_service.dart';
import '../bloc/whitelist_bloc.dart';
import '../bloc/whitelist_event.dart';
import '../bloc/whitelist_state.dart';
import '../pages/whitelist_settings_page.dart';

/// Banner cảnh báo cam hiển thị trên trang chính khi white-list trống
/// (mọi SMS đang bị chặn). Chỉ áp dụng cho thiết bị gửi.
class WhitelistBlockedBanner extends StatelessWidget {
  const WhitelistBlockedBanner({super.key});

  @override
  Widget build(BuildContext context) {
    // Máy nhận đã ghép đôi không dùng white-list của sender — ẩn banner.
    final receiverPairId = context.read<LocalStorageService>().getString(
          StorageKeys.receiverPairId,
        );
    if (receiverPairId != null && receiverPairId.isNotEmpty) {
      return const SizedBox.shrink();
    }

    return BlocProvider(
      create: (ctx) => WhitelistBloc(
        repository: WhitelistRepositoryImpl(
          nativeRelayService: ctx.read<NativeRelayService>(),
        ),
      )..add(const WhitelistStarted()),
      child: const _BannerView(),
    );
  }
}

class _BannerView extends StatelessWidget {
  const _BannerView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<WhitelistBloc, WhitelistState>(
      buildWhen: (p, c) => p.config != c.config || p.isLoading != c.isLoading,
      builder: (context, state) {
        if (state.isLoading || !state.blocksEverything) {
          return const SizedBox.shrink();
        }

        final colorScheme = context.colorScheme;

        return Material(
          color: colorScheme.tertiaryContainer,
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const WhitelistSettingsPage(),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: colorScheme.tertiary,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.whitelistEmptyWarningMessage,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onTertiaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    l10n.whitelistConfigureAction,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onTertiaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

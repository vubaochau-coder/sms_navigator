import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/storage_keys.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/services/local_storage_service.dart';
import '../../../core/widgets/app_switch.dart';

/// Bật/tắt thông báo OTP cho tin do chính máy này relay (BACKLOG 1.8).
/// Không có LocalStorageService trong cây (widget test) → ẩn.
class NotifyOwnRelayedTile extends StatefulWidget {
  const NotifyOwnRelayedTile({super.key});

  @override
  State<NotifyOwnRelayedTile> createState() => _NotifyOwnRelayedTileState();
}

class _NotifyOwnRelayedTileState extends State<NotifyOwnRelayedTile> {
  LocalStorageService? _storage;
  bool _enabled = false;

  @override
  void initState() {
    super.initState();
    try {
      _storage = context.read<LocalStorageService>();
    } catch (_) {
      _storage = null;
    }
    _enabled = _storage?.getBool(StorageKeys.notifyOwnRelayedMessages) ?? false;
  }

  Future<void> _toggle(bool value) async {
    setState(() => _enabled = value);
    await _storage?.setBool(StorageKeys.notifyOwnRelayedMessages, value);
  }

  @override
  Widget build(BuildContext context) {
    if (_storage == null) return const SizedBox.shrink();
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Icon(Icons.notifications_active_outlined, color: colorScheme.onSurfaceVariant),
      title: Text(
        context.l10n.notifyOwnRelayedTitle,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Text(
          context.l10n.notifyOwnRelayedSubtitle,
          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
        ),
      ),
      trailing: AppSwitch(value: _enabled, onChanged: _toggle),
      onTap: () => _toggle(!_enabled),
    );
  }
}

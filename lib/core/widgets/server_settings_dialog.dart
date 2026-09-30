import 'package:flutter/material.dart';

import '../../features/sender/data/services/native_relay_service.dart';
import '../constants/api_endpoints.dart';
import '../services/device_storage_service.dart';
import '../utils/ui_utils.dart';

/// Dialog cài đặt Server URL dùng chung cho Sender & Receiver Dashboard.
///
/// - Đọc URL hiện tại từ [DeviceStorageService].
/// - Lưu URL mới vào storage; `ApiClient` sẽ tự dùng URL mới ở request kế
///   tiếp (đọc động qua serverUrlProvider).
/// - Nếu thiết bị đã ghép đôi (Sender), cập nhật lại `relayUrl` cho Android
///   native để worker vẫn gửi tới đúng server.
class ServerSettingsDialog extends StatefulWidget {
  const ServerSettingsDialog({
    super.key,
    required this.deviceStorageService,
    required this.nativeRelayService,
  });

  final DeviceStorageService deviceStorageService;
  final NativeRelayService nativeRelayService;

  @override
  State<ServerSettingsDialog> createState() => _ServerSettingsDialogState();
}

class _ServerSettingsDialogState extends State<ServerSettingsDialog> {
  late final TextEditingController _urlController;
  bool _isSaving = false;
  bool _isLoading = true;

  static const List<String> _suggestedUrls = [
    'http://10.0.2.2:3000',
    'http://localhost:3000',
  ];

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController();
    _loadCurrentUrl();
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUrl() async {
    final currentUrl = await widget.deviceStorageService.getServerUrl();
    if (!mounted) return;
    setState(() {
      _urlController.text = currentUrl ?? '';
      _isLoading = false;
    });
  }

  String _normalizeUrl(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  Future<void> _save() async {
    final normalizedUrl = _normalizeUrl(_urlController.text);
    final parsedUri = Uri.tryParse(normalizedUrl);
    if (normalizedUrl.isEmpty || parsedUri == null || !parsedUri.hasScheme) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('URL không hợp lệ. Ví dụ: http://192.168.1.10:3000'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await widget.deviceStorageService.saveServerUrl(normalizedUrl);

      // Cập nhật relayUrl cho Android native nếu thiết bị đang ghép đôi.
      final config = await widget.nativeRelayService.getRelayConfig();
      final pairId = config['pairId']?.toString() ?? '';
      if (pairId.isNotEmpty) {
        await widget.nativeRelayService.setRelayConfig(
          isRelayEnabled: config['isRelayEnabled'] == true,
          pairId: pairId,
          sharedSecretBase64: config['sharedSecretBase64']?.toString(),
          relayUrl: '$normalizedUrl${ApiEndpoints.relay}',
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(normalizedUrl);
      UiUtils.showSuccessToast('Đã lưu cấu hình server: $normalizedUrl');
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      UiUtils.showErrorToast('Không thể lưu cấu hình. Thử lại sau.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.dns_rounded, size: 22),
          SizedBox(width: 8),
          Text('Cài Đặt Server'),
        ],
      ),
      content: _isLoading
          ? const SizedBox(
              width: 280,
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Địa chỉ máy chủ chuyển tiếp OTP. Dùng IP LAN hoặc domain để test trên máy thật.',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _urlController,
                  keyboardType: TextInputType.url,
                  enabled: !_isSaving,
                  autocorrect: false,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface,
                    fontFamily: 'monospace',
                  ),
                  decoration: InputDecoration(
                    labelText: 'Server URL',
                    hintText: 'http://192.168.1.10:3000',
                    prefixIcon: const Icon(Icons.link_rounded, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final url in _suggestedUrls)
                      ActionChip(
                        label: Text(url),
                        onPressed: _isSaving
                            ? null
                            : () => _urlController.text = url,
                      ),
                  ],
                ),
              ],
            ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Đóng'),
        ),
        FilledButton.icon(
          onPressed: (_isSaving || _isLoading) ? null : _save,
          icon: const Icon(Icons.save_rounded, size: 18),
          label: const Text('Lưu Cấu Hình'),
        ),
      ],
    );
  }
}

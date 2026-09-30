import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/sender/data/services/native_relay_service.dart';
import '../constants/api_endpoints.dart';
import '../services/device_storage_service.dart';
import '../utils/ui_utils.dart';

/// Dialog cài đặt Server URL dùng chung cho Sender & Receiver Dashboard.
///
/// - Đọc URL hiện tại từ [DeviceStorageService] lấy qua context.
/// - Lưu URL mới vào storage; `ApiClient` sẽ tự dùng URL mới ở request kế
///   tiếp (đọc động qua serverUrlProvider).
/// - Nếu thiết bị đã ghép đôi (Sender), cập nhật lại `relayUrl` cho Android
///   native để worker vẫn gửi tới đúng server.
class ServerSettingsDialog extends StatefulWidget {
  const ServerSettingsDialog({super.key});

  static Future<String?> show([BuildContext? context]) {
    return DialogUtils.showBaseForm<String>(
      const ServerSettingsDialog(),
      context: context,
    );
  }

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
    final storageService = context.read<DeviceStorageService>();
    final currentUrl = await storageService.getServerUrl();
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
      final storageService = context.read<DeviceStorageService>();
      final nativeRelayService = context.read<NativeRelayService>();

      await storageService.saveServerUrl(normalizedUrl);

      // Cập nhật relayUrl cho Android native nếu thiết bị đang ghép đôi.
      final config = await nativeRelayService.getRelayConfig();
      final pairId = config['pairId']?.toString() ?? '';
      if (pairId.isNotEmpty) {
        await nativeRelayService.setRelayConfig(
          isRelayEnabled: config['isRelayEnabled'] == true,
          pairId: pairId,
          sharedSecretBase64: config['sharedSecretBase64']?.toString(),
          relayUrl: '$normalizedUrl${ApiEndpoints.relay}',
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(normalizedUrl);
      UiUtils.showSuccessToast('Đã lưu cấu hình server: $normalizedUrl');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi khi lưu cấu hình: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.dns_rounded),
          SizedBox(width: 8),
          Text('Cấu hình Server URL'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Địa chỉ máy chủ nhận và chuyển tiếp OTP. Cả Sender và Receiver '
              'cần kết nối tới cùng máy chủ.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else ...[
              TextField(
                controller: _urlController,
                keyboardType: TextInputType.url,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: 'Server URL',
                  hintText: 'http://192.168.1.x:3000',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.link_rounded),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () => _urlController.clear(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Gợi ý nhanh:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _suggestedUrls.map((url) {
                  return ActionChip(
                    label: Text(url, style: const TextStyle(fontSize: 11)),
                    onPressed: () {
                      _urlController.text = url;
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              const Text(
                'Lưu ý: Nếu dùng thiết bị thật, hãy dùng địa chỉ IP LAN của máy tính '
                '(ví dụ: http://192.168.1.15:3000).',
                style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        FilledButton.icon(
          onPressed: (_isSaving || _isLoading) ? null : _save,
          icon: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_rounded),
          label: const Text('Lưu'),
        ),
      ],
    );
  }
}

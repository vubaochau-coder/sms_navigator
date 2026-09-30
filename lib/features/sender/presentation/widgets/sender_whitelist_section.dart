import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../bloc/sender_bloc.dart';
import '../bloc/sender_event.dart';

/// Phần giao diện cấu hình danh sách đầu số Whitelist.
class SenderWhitelistSection extends StatefulWidget {
  const SenderWhitelistSection({super.key, required this.whitelist});

  final List<String> whitelist;

  @override
  State<SenderWhitelistSection> createState() => _SenderWhitelistSectionState();
}

class _SenderWhitelistSectionState extends State<SenderWhitelistSection> {
  final TextEditingController _prefixController = TextEditingController();

  final List<Map<String, String>> _quickPresets = const [
    {'label': '+86 (TQ)', 'value': '+86'},
    {'label': '1069 (SMS TQ)', 'value': '1069'},
    {'label': '955xx (Bank TQ)', 'value': '955'},
    {'label': '+84 (VN)', 'value': '+84'},
    {'label': '195 (Viettel)', 'value': '195'},
  ];

  @override
  void dispose() {
    _prefixController.dispose();
    super.dispose();
  }

  void _addPrefix(String value) {
    final clean = value.trim();
    if (clean.isEmpty) return;
    context.read<SenderBloc>().add(SenderAddWhitelistPrefixEvent(clean));
    _prefixController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final whitelist = widget.whitelist;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 28),
        Text(
          'DANH SÁCH ĐẦU SỐ / SỐ ĐIỆN THOẠI ÁP DỤNG',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _quickPresets.map((preset) {
            final isAdded = whitelist.contains(preset['value']);
            return ActionChip(
              avatar: Icon(
                isAdded ? Icons.check_circle : Icons.add_circle_outline,
                size: 16,
                color: isAdded ? AppColors.success : colorScheme.primary,
              ),
              label: Text(
                preset['label']!,
                style: const TextStyle(fontSize: 12),
              ),
              onPressed: isAdded ? null : () => _addPrefix(preset['value']!),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _prefixController,
                decoration: InputDecoration(
                  hintText: 'Nhập số, đầu số (VD: +86, 1069...)',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onSubmitted: _addPrefix,
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonal(
              onPressed: () => _addPrefix(_prefixController.text),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Thêm'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (whitelist.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withAlpha(80),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Chưa có đầu số nào. Hãy bấm các nút gợi ý nhanh ở trên hoặc nhập đầu số cụ thể.',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: whitelist.map((item) {
              return Chip(
                label: Text(
                  item,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () {
                  context.read<SenderBloc>().add(
                    SenderRemoveWhitelistPrefixEvent(item),
                  );
                },
                backgroundColor: colorScheme.surfaceContainerHigh,
                side: BorderSide(color: colorScheme.outlineVariant),
              );
            }).toList(),
          ),
      ],
    );
  }
}

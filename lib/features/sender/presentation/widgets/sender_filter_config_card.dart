import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/sender_bloc.dart';
import '../bloc/sender_event.dart';
import '../bloc/sender_state.dart';
import 'sender_whitelist_section.dart';

/// Thẻ cấu hình bộ lọc SMS & đầu số Whitelist.
class SenderFilterConfigCard extends StatelessWidget {
  const SenderFilterConfigCard({super.key, required this.state});

  final SenderState state;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentMode = state.relayMode;
    final whitelist = state.senderWhitelist;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.filter_list_rounded,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bộ Lọc & Đầu Số Chuyển Tiếp',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Hỗ trợ OTP tiếng Trung & Chuyển tiếp toàn bộ SMS theo đầu số',
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'CHẾ ĐỘ CHUYỂN TIẾP',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          _buildModeOption(
            context: context,
            title: 'Chỉ tin nhắn OTP (VN, EN, CN)',
            subtitle:
                'Tự động nhận diện mã xác thực tiếng Việt, Anh và tiếng Trung (验证码, 动态码, 校验码...)',
            modeValue: 'OTP_ONLY',
            currentMode: currentMode,
            icon: Icons.pin_outlined,
          ),
          const SizedBox(height: 8),
          _buildModeOption(
            context: context,
            title: 'Toàn bộ SMS từ Đầu số Whitelist',
            subtitle:
                'Chuyển tiếp 100% nội dung SMS của các số điện thoại/đầu số trong danh sách',
            modeValue: 'WHITELIST_ALL',
            currentMode: currentMode,
            icon: Icons.format_list_bulleted_rounded,
          ),
          const SizedBox(height: 8),
          _buildModeOption(
            context: context,
            title: 'Chuyển tiếp tất cả SMS (Forward All)',
            subtitle:
                'Chuyển tiếp mọi tin nhắn SMS nhận được sang thiết bị đã ghép đôi',
            modeValue: 'ALL_SMS',
            currentMode: currentMode,
            icon: Icons.all_inclusive_rounded,
          ),
          if (currentMode == 'WHITELIST_ALL')
            SenderWhitelistSection(whitelist: whitelist),
        ],
      ),
    );
  }

  Widget _buildModeOption({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String modeValue,
    required String currentMode,
    required IconData icon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = currentMode == modeValue;

    return InkWell(
      onTap: () {
        context.read<SenderBloc>().add(SenderUpdateRelayModeEvent(modeValue));
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withAlpha(20)
              : colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outlineVariant,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? colorScheme.primary : colorScheme.outline,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorScheme.primary,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

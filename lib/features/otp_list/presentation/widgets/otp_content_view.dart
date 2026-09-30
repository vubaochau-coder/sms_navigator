import 'package:flutter/material.dart';
import '../../../../core/constants/dimens.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../domain/models/decrypted_otp_item.dart';
import 'otp_record_card.dart';

/// View hiển thị nội dung danh sách OTP (dạng phẳng hoặc gom nhóm theo thiết bị).
class OtpContentView extends StatelessWidget {
  const OtpContentView({
    super.key,
    required this.items,
    required this.groupedByDevice,
    required this.isGroupingByDevice,
    required this.dateDisplay,
  });

  final List<DecryptedOtpItem> items;
  final Map<String, List<DecryptedOtpItem>> groupedByDevice;
  final bool isGroupingByDevice;
  final String dateDisplay;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (items.isEmpty) {
      return _buildEmptyState(context, colorScheme);
    }

    if (isGroupingByDevice) {
      return _buildGroupedList(context, colorScheme);
    }

    return _buildFlatList(context);
  }

  Widget _buildFlatList(BuildContext context) {
    return ListView.builder(
      padding: Dimens.screenPadding,
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return OtpRecordCard(item: item);
      },
    );
  }

  Widget _buildGroupedList(BuildContext context, ColorScheme colorScheme) {
    return ListView(
      padding: Dimens.screenPadding,
      children: groupedByDevice.entries.map((entry) {
        final deviceName = entry.key;
        final list = entry.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer.withAlpha(60),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.phone_android_rounded,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        deviceName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${list.length} tin',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ...list.map(
              (item) => OtpRecordCard(item: item),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState(BuildContext context, ColorScheme colorScheme) {
    final l10n = context.l10n;
    final emptyTitle = l10n.otpEmptyInDate(dateDisplay);
    final emptyGuide = l10n.otpEmptyGuide;

    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withAlpha(80),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.mark_email_read_outlined,
                size: 48,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              emptyTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              emptyGuide,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

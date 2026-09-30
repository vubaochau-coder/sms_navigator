import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/dimens.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/utils/ui_utils.dart';
import '../../../../core/widgets/app_common_widgets.dart';
import '../../data/models/paired_device_item.dart';
import '../../data/services/pair_management_service.dart';
import 'pairing_receiver_page.dart';

/// Màn hình xem danh sách thiết bị gửi dành cho Máy Nhận (Receiver).
///
/// Phía người nhận:
/// - Chỉ có thể XEM hiện trạng kết nối (Người gửi đang duy trì hay tạm dừng gửi).
/// - KHÔNG THỂ thay đổi switch trạng thái (Chỉ người gửi mới có quyền kiểm soát).
/// - Có thể hủy kết nối (Unpair) nếu muốn ngừng nhận tin nhắn từ người gửi này.
class PairedSendersPage extends StatefulWidget {
  const PairedSendersPage({
    super.key,
    this.pairManagementService,
  });

  final PairManagementService? pairManagementService;

  @override
  State<PairedSendersPage> createState() => _PairedSendersPageState();
}

class _PairedSendersPageState extends State<PairedSendersPage> {
  late final PairManagementService _service;
  CancelToken? _cancelToken;
  bool _isLoading = true;
  String? _errorMessage;
  List<PairedDeviceItem> _senders = [];

  @override
  void initState() {
    super.initState();
    _service = widget.pairManagementService ??
        DependencyContainer.instance.pairManagementService;
    _fetchSenders();
  }

  @override
  void dispose() {
    _cancelToken?.cancel('PairedSendersPage disposed');
    super.dispose();
  }

  Future<void> _fetchSenders() async {
    _cancelToken?.cancel('Refresh senders');
    final token = CancelToken();
    _cancelToken = token;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await _service.getPairedSenders(cancelToken: token);
      if (!mounted) return;
      setState(() {
        _senders = items;
        _isLoading = false;
      });
    } on RequestCancelledException {
      // Bỏ qua nếu người dùng rời màn hình hoặc refresh
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Không thể tải danh sách thiết bị gửi: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmRevokePair(PairedDeviceItem item) async {
    final confirmed = await UiUtils.showConfirmDialog(
      context,
      title: 'Hủy kết nối máy gửi?',
      message:
          'Bạn có chắc chắn muốn ngắt kết nối với "${item.displayName}"? Bạn sẽ không nhận được OTP từ thiết bị này nữa.',
      confirmText: 'Ngắt kết nối',
      isDestructive: true,
      icon: Icons.link_off_rounded,
    );

    if (!confirmed || !mounted) return;

    final success = await _service.revokePair(item.pairId);
    if (!mounted) return;

    if (success) {
      setState(() {
        _senders.removeWhere((e) => e.pairId == item.pairId);
      });
      UiUtils.showSuccessToast(context, 'Đã hủy kết nối thành công');
    } else {
      UiUtils.showErrorToast(context, 'Không thể hủy kết nối. Vui lòng thử lại!');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thiết bị gửi OTP'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            tooltip: 'Quét QR ghép đôi mới',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PairingReceiverPage()),
              );
              _fetchSenders();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Làm mới',
            onPressed: _fetchSenders,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: Dimens.screenPadding,
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return EmptyStateView(
        icon: Icons.cloud_off_rounded,
        title: 'Có lỗi xảy ra',
        message: _errorMessage,
        actionLabel: 'Thử lại',
        onAction: _fetchSenders,
      );
    }

    if (_senders.isEmpty) {
      return EmptyStateView(
        icon: Icons.phonelink_ring_rounded,
        title: 'Chưa kết nối máy gửi nào',
        message:
            'Thiết bị này chưa nhận OTP từ máy gửi nào. Vui lòng quét mã QR từ máy gửi để hoàn tất ghép đôi.',
        actionLabel: 'Quét mã QR ghép đôi',
        onAction: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PairingReceiverPage()),
          );
          _fetchSenders();
        },
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchSenders,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _senders.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = _senders[index];
          return _buildSenderCard(item);
        },
      ),
    );
  }

  Widget _buildSenderCard(PairedDeviceItem item) {
    return InfoCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (item.isActive ? AppColors.success : AppColors.warning)
                      .withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  item.platform?.toLowerCase() == 'ios'
                      ? Icons.phone_iphone_rounded
                      : Icons.phone_android_rounded,
                  size: 22,
                  color: item.isActive ? AppColors.success : AppColors.warning,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.displayName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Platform: ${item.platform ?? "Android"}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (item.isActive)
                StatusBadge.active(label: 'Đang duy trì gửi')
              else
                StatusBadge.paused(label: 'Người gửi tạm dừng'),
            ],
          ),
          const Divider(height: 20),
          CopyableInfoRow(
            label: 'Pair ID',
            value: item.pairId,
            copySuccessMessage: 'Đã sao chép Pair ID',
          ),
          CopyableInfoRow(
            label: 'Sender ID',
            value: item.deviceId,
            copySuccessMessage: 'Đã sao chép Device ID người gửi',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Text(
                  'Ghép đôi lúc: ',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
                ),
                Text(
                  item.formattedPairedAt,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Text(
                  'Lần nhận gần nhất: ',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
                ),
                Text(
                  item.formattedLastRelayedAt,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Chỉ xem trạng thái (Read-only banner giải thích rõ ràng)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  item.isActive
                      ? Icons.lock_open_rounded
                      : Icons.pause_circle_outline_rounded,
                  size: 16,
                  color: item.isActive ? AppColors.success : AppColors.warning,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.isActive
                        ? 'Người gửi đang duy trì truyền tin. (Chỉ xem)'
                        : 'Người gửi đang tạm dừng truyền tin. (Chỉ xem)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.75),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.link_off_rounded,
                      size: 20, color: AppColors.error),
                  tooltip: 'Hủy ghép đôi',
                  onPressed: () => _confirmRevokePair(item),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

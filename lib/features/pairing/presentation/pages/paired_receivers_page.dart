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
import 'pairing_sender_page.dart';

/// Màn hình quản lý danh sách thiết bị nhận dành cho Máy Gửi (Sender).
///
/// Phía người gửi có thể:
/// - Xem tất cả các thiết bị nhận đã ghép đôi.
/// - Bật/Tắt (active/paused) việc gửi OTP tới từng máy nhận riêng biệt.
/// - Xem chi tiết thời gian ghép đôi và thời điểm chuyển tiếp gần nhất.
/// - Hủy kết nối (Unpair) bất kỳ máy nhận nào.
class PairedReceiversPage extends StatefulWidget {
  const PairedReceiversPage({
    super.key,
    this.pairManagementService,
  });

  final PairManagementService? pairManagementService;

  @override
  State<PairedReceiversPage> createState() => _PairedReceiversPageState();
}

class _PairedReceiversPageState extends State<PairedReceiversPage> {
  late final PairManagementService _service;
  CancelToken? _cancelToken;
  bool _isLoading = true;
  String? _errorMessage;
  List<PairedDeviceItem> _receivers = [];
  final Set<String> _togglingPairIds = {};

  @override
  void initState() {
    super.initState();
    _service = widget.pairManagementService ??
        DependencyContainer.instance.pairManagementService;
    _fetchReceivers();
  }

  @override
  void dispose() {
    _cancelToken?.cancel('PairedReceiversPage disposed');
    super.dispose();
  }

  Future<void> _fetchReceivers() async {
    _cancelToken?.cancel('Refresh receivers');
    final token = CancelToken();
    _cancelToken = token;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await _service.getPairedReceivers(cancelToken: token);
      if (!mounted) return;
      setState(() {
        _receivers = items;
        _isLoading = false;
      });
    } on RequestCancelledException {
      // Bỏ qua nếu người dùng rời màn hình hoặc refresh
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Không thể tải danh sách thiết bị nhận: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleActive(PairedDeviceItem item, bool newValue) async {
    if (_togglingPairIds.contains(item.pairId)) return;

    setState(() => _togglingPairIds.add(item.pairId));

    final success = await _service.togglePairActive(
      pairId: item.pairId,
      isActive: newValue,
    );

    if (!mounted) return;
    setState(() => _togglingPairIds.remove(item.pairId));

    if (success) {
      setState(() {
        final index = _receivers.indexWhere((e) => e.pairId == item.pairId);
        if (index != -1) {
          _receivers[index] = item.copyWith(isActive: newValue);
        }
      });
      UiUtils.showSuccessToast(
        context,
        newValue
            ? 'Đã bật chuyển tiếp tới ${item.displayName}'
            : 'Đã tạm dừng chuyển tiếp tới ${item.displayName}',
      );
    } else {
      UiUtils.showErrorToast(
        context,
        'Không thể cập nhật trạng thái. Vui lòng thử lại!',
      );
    }
  }

  Future<void> _confirmRevokePair(PairedDeviceItem item) async {
    final confirmed = await UiUtils.showConfirmDialog(
      context,
      title: 'Hủy kết nối thiết bị?',
      message:
          'Bạn có chắc chắn muốn ngắt kết nối với "${item.displayName}"? Thiết bị này sẽ không thể nhận OTP từ bạn nữa.',
      confirmText: 'Ngắt kết nối',
      isDestructive: true,
      icon: Icons.link_off_rounded,
    );

    if (!confirmed || !mounted) return;

    final success = await _service.revokePair(item.pairId);
    if (!mounted) return;

    if (success) {
      setState(() {
        _receivers.removeWhere((e) => e.pairId == item.pairId);
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
        title: const Text('Thiết bị nhận OTP'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_rounded),
            tooltip: 'Ghép nối thêm thiết bị',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PairingSenderPage()),
              );
              _fetchReceivers();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Làm mới',
            onPressed: _fetchReceivers,
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
        onAction: _fetchReceivers,
      );
    }

    if (_receivers.isEmpty) {
      return EmptyStateView(
        icon: Icons.phonelink_erase_rounded,
        title: 'Chưa có thiết bị nhận nào',
        message:
            'Hiện tại chưa có máy nhận nào ghép đôi với thiết bị này. Bấm nút bên dưới để tạo mã QR kết nối.',
        actionLabel: 'Tạo mã QR ghép đôi',
        onAction: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PairingSenderPage()),
          );
          _fetchReceivers();
        },
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchReceivers,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _receivers.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = _receivers[index];
          return _buildReceiverCard(item);
        },
      ),
    );
  }

  Widget _buildReceiverCard(PairedDeviceItem item) {
    final isToggling = _togglingPairIds.contains(item.pairId);

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
                StatusBadge.active(label: 'Đang gửi')
              else
                StatusBadge.paused(label: 'Đã tạm dừng'),
            ],
          ),
          const Divider(height: 20),
          CopyableInfoRow(
            label: 'Pair ID',
            value: item.pairId,
            copySuccessMessage: 'Đã sao chép Pair ID',
          ),
          CopyableInfoRow(
            label: 'Device ID',
            value: item.deviceId,
            copySuccessMessage: 'Đã sao chép Device ID người nhận',
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
                  'Lần gửi gần nhất: ',
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
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (isToggling)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Switch(
                      value: item.isActive,
                      activeTrackColor: AppColors.success,
                      onChanged: (val) => _toggleActive(item, val),
                    ),
                  const SizedBox(width: 8),
                  Text(
                    item.isActive ? 'Cho phép gửi OTP' : 'Tạm dừng gửi OTP',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: item.isActive
                          ? AppColors.success
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.link_off_rounded, color: AppColors.error),
                tooltip: 'Hủy ghép đôi',
                onPressed: () => _confirmRevokePair(item),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

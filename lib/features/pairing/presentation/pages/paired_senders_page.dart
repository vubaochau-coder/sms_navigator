import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/dimens.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/utils/ui_utils.dart';
import '../../../../core/widgets/app_common_widgets.dart';
import '../../data/models/paired_device_item.dart';
import '../../data/services/pair_management_service.dart';
import '../widgets/paired_sender_card.dart';
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
          return PairedSenderCard(
            item: item,
            onRevokePair: () => _confirmRevokePair(item),
          );
        },
      ),
    );
  }
}

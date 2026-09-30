import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/dimens.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/services/fcm_notification_service.dart';
import '../widgets/notification_info_cards.dart';
import '../widgets/notification_mockup_cards.dart';
import '../widgets/notification_presets_selector.dart';

class NotificationTestPage extends StatefulWidget {
  const NotificationTestPage({super.key});

  @override
  State<NotificationTestPage> createState() => _NotificationTestPageState();
}

class _NotificationTestPageState extends State<NotificationTestPage> {
  final TextEditingController _senderController =
      TextEditingController(text: 'Vietcombank');
  final TextEditingController _otpController =
      TextEditingController(text: '849201');
  final TextEditingController _messageController = TextEditingController(
    text:
        'GD 849201 tai VCB DIGIBANK luc 22:30. Khong chia se ma OTP cho bat ky ai.',
  );
  final TextEditingController _targetDeviceController =
      TextEditingController(text: 'Samsung S24 (Malaysia)');

  String? _fcmToken;
  bool _hasNotificationPermission = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final status = await Permission.notification.status;
    final token =
        await DependencyContainer.instance.deviceStorageService.getFcmToken();
    if (mounted) {
      setState(() {
        _hasNotificationPermission = status.isGranted;
        _fcmToken = token;
      });
    }
  }

  void _randomizeOtp() {
    final randomOtp =
        (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();
    setState(() {
      _otpController.text = randomOtp;
      _messageController.text =
          'GD $randomOtp tai ${_senderController.text} DIGIBANK luc 22:35. Khong chia se ma OTP.';
    });
  }

  Future<void> _triggerReceiverNotification() async {
    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    await FcmNotificationService.showDemoReceiverOtpNotification(
      sender: _senderController.text.trim(),
      otp: _otpController.text.trim(),
      rawMessage: _messageController.text.trim(),
    );

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã bắn thông báo: [${_senderController.text}] Mã OTP: ${_otpController.text}',
          ),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _triggerSenderNotification() async {
    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    await FcmNotificationService.showDemoSenderSuccessNotification(
      sender: _senderController.text.trim(),
      otp: _otpController.text.trim(),
      targetDevice: _targetDeviceController.text.trim(),
    );

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã bắn thông báo: Gửi thành công mã ${_otpController.text} sang máy nhận!',
          ),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _requestPermission() async {
    final result = await Permission.notification.request();
    setState(() {
      _hasNotificationPermission = result.isGranted;
    });
    if (result.isGranted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cấp quyền thông báo thành công!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thử Nghiệm Push Notification'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shuffle_rounded),
            tooltip: 'Sinh mã OTP ngẫu nhiên',
            onPressed: _randomizeOtp,
          ),
        ],
      ),
      body: ListView(
        padding: Dimens.screenPadding,
        children: [
          NotificationHeaderCard(colorScheme: colorScheme),
          const SizedBox(height: 12),
          if (!_hasNotificationPermission) ...[
            NotificationPermissionWarningCard(
              onRequestPermission: _requestPermission,
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 12),
          ],
          NotificationSectionTitle(
            title: '1. UI Thông Báo Máy Nhận (B) — Khi Có OTP Đến',
            subtitle: 'Mô phỏng trải nghiệm Heads-up Notification khi nhận OTP',
            icon: Icons.mark_chat_unread_rounded,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 8),
          ReceiverNotificationMockup(
            sender: _senderController.text,
            otp: _otpController.text,
            rawMessage: _messageController.text,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 8),
          Text(
            'Ngân hàng Việt Nam:',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          BankPresetsSelector(
            presets: NotificationPresetsData.bankPresets,
            selected: _senderController.text,
            onSelected: (val) {
              setState(() {
                _senderController.text = val;
                _messageController.text =
                    'GD ${_otpController.text} tai $val luc 22:30. Khong chia se ma OTP.';
              });
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Mẫu Tiếng Trung & Toàn bộ SMS:',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          ChinesePresetsSelector(
            currentSender: _senderController.text,
            currentOtp: _otpController.text,
            onSelected: (item) {
              setState(() {
                _senderController.text = item.sender;
                _otpController.text = item.otp;
                _messageController.text = item.message;
              });
            },
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: AppColors.success,
            ),
            icon: const Icon(Icons.notifications_active_rounded),
            label: Text(
              _isLoading
                  ? 'Đang phát thông báo...'
                  : 'Bắn Thử Thông Báo Nhận OTP (Device B)',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: _isLoading ? null : _triggerReceiverNotification,
          ),
          const SizedBox(height: 20),
          NotificationSectionTitle(
            title: '2. UI Thông Báo Máy Gửi (A) — Chuyển Tiếp Thành Công',
            subtitle: 'Mô phỏng trạng thái thông báo xác nhận gửi OTP sang B',
            icon: Icons.send_rounded,
            color: colorScheme.secondary,
          ),
          const SizedBox(height: 8),
          SenderNotificationMockup(
            sender: _senderController.text,
            otp: _otpController.text,
            targetDevice: _targetDeviceController.text,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 10),
          FilledButton.tonalIcon(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.check_circle_outline_rounded),
            label: const Text(
              'Bắn Thử Thông Báo Gửi Thành Công (Device A)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: _isLoading ? null : _triggerSenderNotification,
          ),
          const SizedBox(height: 20),
          FcmStatusCard(
            fcmToken: _fcmToken,
            hasPermission: _hasNotificationPermission,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

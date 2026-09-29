import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/dimens.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/services/fcm_notification_service.dart';

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

  final List<String> _bankPresets = [
    'Vietcombank',
    'Techcombank',
    'MBBank',
    'BIDV',
    'VPBank',
    'ShopeePay',
  ];

  final List<Map<String, String>> _chinesePresets = [
    {
      'label': '招商银行 (849201)',
      'sender': '95555',
      'otp': '849201',
      'message': '【招商银行】您的验证码是 849201，5分钟内有效，请勿向任何人泄露。',
    },
    {
      'label': '中国工商银行 (192837)',
      'sender': '95588',
      'otp': '192837',
      'message': '【中国工商银行】您正在办理网银转账，动态密码为 192837，切勿向他人泄露。',
    },
    {
      'label': '支付宝 (749201)',
      'sender': 'Alipay',
      'otp': '749201',
      'message': '【支付宝】验证码：749201，用于登录。任何人索取均为诈骗。',
    },
    {
      'label': '腾讯科技 (849201)',
      'sender': '10690001',
      'otp': '849201',
      'message': '【腾讯科技】849201（动态验证码），请在30分钟内填写。',
    },
    {
      'label': '建行 SMS Biến động (Toàn bộ)',
      'sender': '95533',
      'otp': '8888',
      'message': '【中国建设银行】您尾号8888账户09月29日22:45支出人民币1,500.00元，活期余额12,890.50元。',
    },
  ];

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
          _HeaderCard(colorScheme: colorScheme),
          const SizedBox(height: 12),
          if (!_hasNotificationPermission) ...[
            _PermissionWarningCard(
              onRequestPermission: _requestPermission,
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 12),
          ],
          _SectionTitle(
            title: '1. UI Thông Báo Máy Nhận (B) — Khi Có OTP Đến',
            subtitle: 'Mô phỏng trải nghiệm Heads-up Notification khi nhận OTP',
            icon: Icons.mark_chat_unread_rounded,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 8),
          _ReceiverNotificationMockup(
            sender: _senderController.text,
            otp: _otpController.text,
            rawMessage: _messageController.text,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Ngân hàng Việt Nam:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _BankPresetsSelector(
            presets: _bankPresets,
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
          Row(
            children: [
              Text(
                'Mẫu Tiếng Trung & Toàn bộ SMS:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _chinesePresets.map((item) {
                final isSelected = _senderController.text == item['sender'] &&
                    _otpController.text == item['otp'];
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(
                      item['label']!,
                      style: const TextStyle(fontSize: 12),
                    ),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        _senderController.text = item['sender']!;
                        _otpController.text = item['otp']!;
                        _messageController.text = item['message']!;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
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
          _SectionTitle(
            title: '2. UI Thông Báo Máy Gửi (A) — Chuyển Tiếp Thành Công',
            subtitle: 'Mô phỏng trạng thái thông báo xác nhận gửi OTP sang B',
            icon: Icons.send_rounded,
            color: colorScheme.secondary,
          ),
          const SizedBox(height: 8),
          _SenderNotificationMockup(
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
          _FcmStatusCard(
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

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer,
            colorScheme.surfaceContainerHigh,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kiểm Thử Trực Quan Thông Báo Push',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Bấm nút bên dưới để vừa kích hoạt thông báo hệ thống thực tế trên thanh Status bar, vừa xem Mockup UI trực quan.',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionWarningCard extends StatelessWidget {
  const _PermissionWarningCard({
    required this.onRequestPermission,
    required this.colorScheme,
  });

  final VoidCallback onRequestPermission;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Chưa cấp quyền thông báo. Vui lòng cho phép để xem thông báo nổi trên màn hình.',
              style: TextStyle(fontSize: 12, color: colorScheme.onSurface),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
            ),
            onPressed: onRequestPermission,
            child: const Text('Cấp Quyền'),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Mockup trực quan dạng Heads-up banner của thông báo nhận OTP (Device B).
class _ReceiverNotificationMockup extends StatelessWidget {
  const _ReceiverNotificationMockup({
    required this.sender,
    required this.otp,
    required this.rawMessage,
    required this.colorScheme,
  });

  final String sender;
  final String otp;
  final String rawMessage;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    Text(
                      'SMS NAVIGATOR',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.successLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'E2EE Verified',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'vừa xong',
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '🔐 Mã OTP từ $sender',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'OTP: ',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  otp,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: 2.0,
                    color: colorScheme.primary,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            rawMessage,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                icon: const Icon(Icons.copy_rounded, size: 14),
                label: const Text('Sao chép mã', style: TextStyle(fontSize: 12)),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: otp));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Đã sao chép mã $otp')),
                  );
                },
              ),
              const SizedBox(width: 8),
              TextButton(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                child: const Text('Mở chi tiết', style: TextStyle(fontSize: 12)),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Mockup trực quan thông báo chuyển tiếp OTP thành công (Device A).
class _SenderNotificationMockup extends StatelessWidget {
  const _SenderNotificationMockup({
    required this.sender,
    required this.otp,
    required this.targetDevice,
    required this.colorScheme,
  });

  final String sender;
  final String otp;
  final String targetDevice;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 14),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'SMS NAVIGATOR • RELAY SENDER',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: cs.primary,
                  ),
                ),
              ),
              Text(
                'vừa xong',
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '✅ Chuyển Tiếp OTP Thành Công',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Đã chuyển mã $otp (từ $sender) tới $targetDevice an toàn qua đường truyền mã hóa E2EE.',
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurfaceVariant,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _BankPresetsSelector extends StatelessWidget {
  const _BankPresetsSelector({
    required this.presets,
    required this.selected,
    required this.onSelected,
  });

  final List<String> presets;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: presets.map((p) {
          final isSelected = p == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: FilterChip(
              label: Text(p, style: const TextStyle(fontSize: 12)),
              selected: isSelected,
              onSelected: (_) => onSelected(p),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FcmStatusCard extends StatelessWidget {
  const _FcmStatusCard({
    required this.fcmToken,
    required this.hasPermission,
    required this.colorScheme,
  });

  final String? fcmToken;
  final bool hasPermission;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  size: 16, color: colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                'Thông Tin FCM Device Token',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            fcmToken != null && fcmToken!.isNotEmpty
                ? 'FCM Token: ${fcmToken!.substring(0, fcmToken!.length > 30 ? 30 : fcmToken!.length)}...'
                : 'Chưa lấy được FCM Token (chạy trên giả lập không có Play Services hoặc offline).',
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (fcmToken != null && fcmToken!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.copy, size: 12),
                label: const Text('Sao chép toàn bộ Token',
                    style: TextStyle(fontSize: 11)),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: fcmToken!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Đã sao chép FCM Token vào bộ nhớ tạm!')),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

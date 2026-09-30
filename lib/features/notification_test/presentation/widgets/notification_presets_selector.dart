import 'package:flutter/material.dart';

class ChinesePresetItem {
  final String label;
  final String sender;
  final String otp;
  final String message;

  const ChinesePresetItem({
    required this.label,
    required this.sender,
    required this.otp,
    required this.message,
  });
}

class NotificationPresetsData {
  static const List<String> bankPresets = [
    'Vietcombank',
    'Techcombank',
    'MBBank',
    'BIDV',
    'VPBank',
    'ShopeePay',
  ];

  static const List<ChinesePresetItem> chinesePresets = [
    ChinesePresetItem(
      label: '招商银行 (849201)',
      sender: '95555',
      otp: '849201',
      message: '【招商银行】您的验证码是 849201，5分钟内有效，请勿向任何人泄露。',
    ),
    ChinesePresetItem(
      label: '中国工商银行 (192837)',
      sender: '95588',
      otp: '192837',
      message: '【中国工商银行】您正在办理网银转账，动态密码为 192837，切勿向他人泄露。',
    ),
    ChinesePresetItem(
      label: '支付宝 (749201)',
      sender: 'Alipay',
      otp: '749201',
      message: '【支付宝】验证码：749201，用于登录。任何人索取均为诈骗。',
    ),
    ChinesePresetItem(
      label: '腾讯科技 (849201)',
      sender: '10690001',
      otp: '849201',
      message: '【腾讯科技】849201（动态验证码），请在30分钟内填写。',
    ),
    ChinesePresetItem(
      label: '建行 SMS Biến động (Toàn bộ)',
      sender: '95533',
      otp: '8888',
      message: '【中国建设银行】您尾号8888账户09月29日22:45支出人民币1,500.00元，活期余额12,890.50元。',
    ),
  ];
}

class BankPresetsSelector extends StatelessWidget {
  const BankPresetsSelector({
    super.key,
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

class ChinesePresetsSelector extends StatelessWidget {
  const ChinesePresetsSelector({
    super.key,
    required this.currentSender,
    required this.currentOtp,
    required this.onSelected,
  });

  final String currentSender;
  final String currentOtp;
  final ValueChanged<ChinesePresetItem> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: NotificationPresetsData.chinesePresets.map((item) {
          final isSelected =
              currentSender == item.sender && currentOtp == item.otp;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: FilterChip(
              label: Text(item.label, style: const TextStyle(fontSize: 12)),
              selected: isSelected,
              onSelected: (_) => onSelected(item),
            ),
          );
        }).toList(),
      ),
    );
  }
}

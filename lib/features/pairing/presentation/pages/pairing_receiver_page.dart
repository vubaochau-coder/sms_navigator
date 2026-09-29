import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../receiver/presentation/pages/receiver_dashboard_page.dart';
import '../bloc/pairing_bloc.dart';
import '../bloc/pairing_event.dart';
import '../bloc/pairing_state.dart';

class PairingReceiverPage extends StatefulWidget {
  const PairingReceiverPage({super.key});

  @override
  State<PairingReceiverPage> createState() => _PairingReceiverPageState();
}

class _PairingReceiverPageState extends State<PairingReceiverPage> {
  final GlobalKey<_OtpInputRowState> _otpKey = GlobalKey();
  String _otpCode = '';

  /// Lưu lỗi đã hiển thị để tránh SnackBar/clear lặp lại khi state đổi
  /// do countdown tick (errorMessage vẫn giữ nguyên giữa các tick).
  String? _shownError;

  void _onOtpChanged(String code) {
    setState(() => _otpCode = code);
  }

  void _onOtpCompleted(String code) {
    _shownError = null;
    context.read<PairingBloc>().add(PairingSubmitReceiverCodeEvent(code));
  }

  void _onManualSubmit() {
    if (_otpCode.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đủ 6 chữ số.')),
      );
      return;
    }
    _onOtpCompleted(_otpCode);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhập Mã Ghép Đôi'),
      ),
      body: BlocConsumer<PairingBloc, PairingState>(
        listener: (context, state) {
          if (state.isSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ghép đôi thành công! Thiết bị đã sẵn sàng nhận OTP.'),
              ),
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ReceiverDashboardPage()),
            );
          } else if (state.errorMessage != null &&
              _shownError != state.errorMessage) {
            _shownError = state.errorMessage;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
            _otpKey.currentState?.clear();
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 8),
                const _HeaderIcon(),
                const SizedBox(height: 24),
                Text('Kết Nối Thiết Bị', style: theme.textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  'Nhập mã 6 số hiển thị trên Thiết Bị Gửi.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),
                _OtpInputRow(
                  key: _otpKey,
                  onChanged: _onOtpChanged,
                  onCompleted: _onOtpCompleted,
                ),
                if (_otpCode.length < 6) ...[
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: state.isLoading ? null : _onManualSubmit,
                      child: state.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Xác Nhận Ghép Đôi'),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.secondary, colorScheme.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.secondary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Icon(
        Icons.phonelink_ring_outlined,
        color: Colors.white,
        size: 38,
      ),
    );
  }
}

class _OtpInputRow extends StatefulWidget {
  const _OtpInputRow({
    super.key,
    required this.onChanged,
    required this.onCompleted,
  });

  final ValueChanged<String> onChanged;
  final ValueChanged<String> onCompleted;

  @override
  State<_OtpInputRow> createState() => _OtpInputRowState();
}

class _OtpInputRowState extends State<_OtpInputRow> {
  static const int _digitCount = 6;

  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_digitCount, (_) => TextEditingController());
    _focusNodes = List.generate(_digitCount, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  String get _code =>
      [for (final controller in _controllers) controller.text].join();

  /// Reset toàn bộ ô input về rỗng và focus về ô đầu tiên (dùng khi có lỗi).
  void clear() {
    for (final controller in _controllers) {
      controller.clear();
    }
    _focusNodes.first.requestFocus();
    widget.onChanged('');
  }

  void _handleChanged(int index, String value) {
    if (value.isNotEmpty) {
      if (index < _digitCount - 1) {
        _focusNodes[index + 1].requestFocus();
      }
    } else if (index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    final code = _code;
    widget.onChanged(code);
    if (index == _digitCount - 1 && code.length == _digitCount) {
      widget.onCompleted(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(
        _digitCount,
        (index) => _OtpCell(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          onChanged: (value) => _handleChanged(index, value),
        ),
      ),
    );
  }
}

class _OtpCell extends StatelessWidget {
  const _OtpCell({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: focusNode,
      builder: (context, _) {
        final isFocused = focusNode.hasFocus;
        return Container(
          width: 44,
          height: 56,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isFocused ? colorScheme.primary : colorScheme.outline,
              width: isFocused ? 2 : 1.5,
            ),
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
            decoration: const InputDecoration(
              counterText: '',
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: onChanged,
          ),
        );
      },
    );
  }
}

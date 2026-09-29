import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
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
  final TextEditingController _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                backgroundColor: AppColors.success,
              ),
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ReceiverDashboardPage()),
            );
          } else if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                const Icon(
                  Icons.phonelink_ring_outlined,
                  size: 64,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Kết Nối Với Máy Gửi (Việt Nam)',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Vui lòng nhập mã 6 số hiển thị trên màn hình Máy Gửi để hoàn tất ghép đôi.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 36),
                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 12,
                    fontFamily: 'monospace',
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '••••••',
                    hintStyle: const TextStyle(letterSpacing: 12),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: state.isLoading
                        ? null
                        : () {
                            final code = _codeController.text.trim();
                            if (code.length == 6) {
                              context
                                  .read<PairingBloc>()
                                  .add(PairingSubmitReceiverCodeEvent(code));
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Vui lòng nhập đủ 6 chữ số.'),
                                ),
                              );
                            }
                          },
                    child: state.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Xác Nhận Ghép Đôi'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

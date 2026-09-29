import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../bloc/pairing_bloc.dart';
import '../bloc/pairing_event.dart';
import '../bloc/pairing_state.dart';

class PairingSenderPage extends StatefulWidget {
  const PairingSenderPage({super.key});

  @override
  State<PairingSenderPage> createState() => _PairingSenderPageState();
}

class _PairingSenderPageState extends State<PairingSenderPage> {
  @override
  void initState() {
    super.initState();
    context.read<PairingBloc>().add(const PairingGenerateSenderCodeEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ghép Đôi Thiết Bị'),
      ),
      body: BlocBuilder<PairingBloc, PairingState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final payload = state.pairingPayload;
          if (payload == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Không thể tạo mã ghép đôi.'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      context
                          .read<PairingBloc>()
                          .add(const PairingGenerateSenderCodeEvent());
                    },
                    child: const Text('Thử Lại'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Mã Ghép Đôi Của Bạn',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Nhập 6 số này trên Máy Nhận (Malaysia) để thiết lập kênh mã hóa E2EE an toàn.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                // 6-digit Code Box
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                  child: Text(
                    payload.code,
                    style: const TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 10,
                      color: AppColors.primary,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                // QR Code
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: QrImageView(
                    data: payload.code,
                    version: QrVersions.auto,
                    size: 200.0,
                  ),
                ),
                const SizedBox(height: 20),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock, size: 16, color: AppColors.success),
                    SizedBox(width: 6),
                    Text(
                      'Kênh truyền mã hóa đầu cuối AES-256-GCM',
                      style: TextStyle(fontSize: 12, color: AppColors.success),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Hoàn Tất & Bắt Đầu Chuyển Tiếp'),
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

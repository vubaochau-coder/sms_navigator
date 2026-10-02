import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/pairing_payload_model.dart';
import '../bloc/pairing_bloc.dart';
import '../bloc/pairing_event.dart';
import '../../../scanner/presentation/scanning/qr_scan_handler.dart';

/// Handler ghép đôi: nhận diện payload QR phiên bản 2 và điều phối vào
/// [PairingBloc], theo dõi kết quả để báo về phiên quét.
class PairingQrScanHandler implements QrScanHandler {
  StreamSubscription<Object?>? _subscription;

  @override
  bool canHandle(String raw) => PairingPayloadModel.looksLikePairingQr(raw);

  @override
  void handleScan(BuildContext context, QrScanFlow flow, String raw) {
    final bloc = context.read<PairingBloc>();
    _subscription?.cancel();
    _subscription = bloc.stream.listen((state) {
      if (state.isSuccess) {
        _cancel();
        flow.complete();
      } else if (state.errorMessage != null) {
        _cancel();
        flow.fail();
      }
    });
    bloc.add(PairingSubmitReceiverQrEvent(raw));
  }

  void _cancel() {
    _subscription?.cancel();
    _subscription = null;
  }

  @override
  void dispose() => _cancel();
}

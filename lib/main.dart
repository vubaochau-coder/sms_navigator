import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app.dart';
import 'core/bloc/app_bloc_observer.dart';
import 'core/bootstrap/app_bootstrap.dart';
import 'core/services/crashlytics_service.dart';
import 'core/services/fcm_notification_service.dart';
import 'core/storage/local_storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Firebase sớm
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('Firebase not available in current environment: $e');
  }

  // Khởi tạo hệ thống bắt lỗi tập trung (FlutterError + PlatformDispatcher)
  await CrashlyticsService.instance.initialize();

  // Đăng ký BLoC observer theo dõi sự cố và biến đổi trạng thái của toàn bộ Blocs
  Bloc.observer = AppBlocObserver();

  // Khởi tạo Local Storage sớm (trước khi dựng cây Widget)
  final localStorage = await LocalStorageService.create();

  runApp(
    AppBootstrap(
      localStorageService: localStorage,
      child: const OtpRelayApp(),
    ),
  );
}

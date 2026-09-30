import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'app.dart';
import 'core/di/injection.dart';
import 'core/services/fcm_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Firebase
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('Firebase not available in current environment: $e');
  }

  // Khởi tạo Dependency Injection
  final di = DependencyContainer.instance;
  di.init();

  // Khởi tạo Firebase Crashlytics & Analytics
  await di.crashlyticsService.initialize();
  di.analyticsService.initialize();

  // Khởi tạo FCM notification service (kênh thông báo, đăng ký token, lắng nghe tin nhắn)
  await di.fcmNotificationService.initialize();

  runApp(const OtpRelayApp());
}

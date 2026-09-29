import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/device/data/services/device_api_service.dart';
import '../../features/receiver/data/models/received_otp_model.dart';
import '../../features/receiver/data/services/receiver_storage_service.dart';
import '../utils/crypto_helper.dart';
import 'device_storage_service.dart';

/// Top-level background message handler cho Firebase Messaging.
/// Được gọi khi app ở chế độ Background hoặc Terminated.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  await FcmNotificationService.processIncomingRemoteMessage(message);
}

/// Dịch vụ quản lý FCM Notifications & High-priority Local Notifications.
class FcmNotificationService {
  FcmNotificationService({
    required this.deviceStorageService,
    required this.deviceApiService,
    required this.receiverStorageService,
  });

  final DeviceStorageService deviceStorageService;
  final DeviceApiService deviceApiService;
  final ReceiverStorageService receiverStorageService;

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static final StreamController<ReceivedOtpModel> _otpStreamController =
      StreamController<ReceivedOtpModel>.broadcast();

  /// Stream thông báo OTP đã giải mã thành công theo thời gian thực tới UI.
  static Stream<ReceivedOtpModel> get onOtpReceived =>
      _otpStreamController.stream;

  static const String channelId = 'sms_navigator_otp_channel';
  static const String channelName = 'Thông Báo Mã OTP';
  static const String channelDesc =
      'Nhận và hiển thị tức thì mã OTP xác thực được chuyển tiếp qua E2EE';

  /// Khởi tạo Firebase Messaging, Local Notifications và đăng ký Token.
  Future<void> initialize() async {
    try {
      // 1. Cấu hình FlutterLocalNotificationsPlugin cho Android
      const androidInit =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidInit);

      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (details) {
          debugPrint('Notification tapped: ${details.payload}');
        },
      );

      // 2. Tạo Notification Channel với mức ưu tiên cao nhất (Heads-up notification)
      final androidChannel = AndroidNotificationChannel(
        channelId,
        channelName,
        description: channelDesc,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(androidChannel);

      // 3. Yêu cầu quyền thông báo (Android 13+ POST_NOTIFICATIONS)
      await _requestPermissions();

      // 4. Lấy và đồng bộ FCM token
      await _syncFcmToken();

      // 5. Lắng nghe cập nhật token định kỳ
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        await deviceStorageService.saveFcmToken(newToken);
        try {
          await deviceApiService.updateFcmToken(newToken);
        } catch (e) {
          debugPrint('Failed to sync refreshed FCM token: $e');
        }
      });

      // 6. Lắng nghe tin nhắn khi App đang ở Foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        final otp = await processIncomingRemoteMessage(message);
        if (otp != null) {
          _otpStreamController.add(otp);
        }
      });

      // 7. Lắng nghe người dùng bấm vào notification mở app
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
        final otp = await processIncomingRemoteMessage(message);
        if (otp != null) {
          _otpStreamController.add(otp);
        }
      });
    } catch (e) {
      debugPrint('FcmNotificationService init error (running in fallback): $e');
    }
  }

  Future<void> _requestPermissions() async {
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
    }
  }

  Future<void> _syncFcmToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await deviceStorageService.saveFcmToken(token);
        try {
          await deviceApiService.updateFcmToken(token);
          debugPrint('FCM Token synced successfully: ${token.substring(0, 15)}...');
        } catch (e) {
          debugPrint('Failed to update FCM token with server: $e');
        }
      }
    } catch (e) {
      debugPrint('Could not retrieve FCM token: $e');
    }
  }

  /// Xử lý giải mã và hiển thị thông báo cho một tin nhắn FCM đến.
  static Future<ReceivedOtpModel?> processIncomingRemoteMessage(
    RemoteMessage message,
  ) async {
    final data = message.data;
    if (data.isEmpty) return null;

    final type = data['type']?.toString();
    if (type != 'OTP_RELAY') return null;

    final pairId = data['pair_id']?.toString() ?? '';
    final encryptedPayload = data['encrypted_payload']?.toString() ?? '';
    final iv = data['iv']?.toString() ?? '';

    if (encryptedPayload.isEmpty || iv.isEmpty) return null;

    try {
      // Đọc secret key ghép đôi từ SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final storedPairId = prefs.getString('receiver_pair_id');
      final sharedSecret = prefs.getString('receiver_shared_secret');

      if (sharedSecret == null || sharedSecret.isEmpty) {
        debugPrint('Cannot decrypt OTP relay: No shared secret found on receiver');
        return null;
      }

      // Xác minh pairId nếu có
      if (storedPairId != null && storedPairId.isNotEmpty && pairId.isNotEmpty) {
        if (storedPairId != pairId) {
          debugPrint('Pair ID mismatch ($storedPairId vs $pairId), skipping');
          return null;
        }
      }

      // Giải mã AES-256-GCM
      final decryptedJson = await CryptoHelper.decryptAesGcm256(
        ciphertextWithTagBase64: encryptedPayload,
        ivBase64: iv,
        secretKeyBase64: sharedSecret,
      );

      final Map<String, dynamic> payload = jsonDecode(decryptedJson);
      final sender = payload['sender']?.toString() ?? 'OTP Service';
      final otp = payload['otp']?.toString() ?? '';
      final rawMessage = payload['message']?.toString() ??
          payload['rawMessage']?.toString() ??
          '';

      if (otp.isEmpty) return null;

      final now = DateTime.now().millisecondsSinceEpoch;
      final model = ReceivedOtpModel(
        id: 'otp_${now}_${otp.hashCode}',
        sender: sender,
        otp: otp,
        receivedAt: now,
        expiresAt: now + (5 * 60 * 1000), // 5 phút hiệu lực
        rawMessage: rawMessage,
      );

      // Lưu vào lịch sử nhận OTP
      final storage = ReceiverStorageServiceImpl();
      await storage.saveReceivedOtp(model);

      // Hiển thị thông báo nổi (Heads-up notification) nếu platform hỗ trợ
      try {
        await _showLocalOtpNotification(model);
      } catch (e) {
        debugPrint('Could not show local notification: $e');
      }

      return model;
    } catch (e, s) {
      debugPrint('Error processing OTP relay message: $e\n$s');
      return null;
    }
  }

  static Future<void> _showLocalOtpNotification(ReceivedOtpModel otp) async {
    const androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc,
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'Mã OTP mới',
      styleInformation: BigTextStyleInformation(''),
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.message,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    final notificationId =
        (DateTime.now().millisecondsSinceEpoch % 100000).toInt();

    await _localNotifications.show(
      id: notificationId,
      title: '🔐 OTP từ ${otp.sender}: ${otp.otp}',
      body: 'Mã OTP: ${otp.otp} • Chạm để mở ứng dụng',
      notificationDetails: notificationDetails,
      payload: otp.otp,
    );
  }

  /// Bắn thông báo demo cho tình huống: Máy B nhận được OTP từ Máy A.
  static Future<void> showDemoReceiverOtpNotification({
    String sender = 'Vietcombank',
    String otp = '849201',
    String rawMessage =
        'GD 849201 tai VCB DIGIBANK luc 22:30. Khong chia se ma OTP cho bat ky ai.',
  }) async {
    const androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc,
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'Mã OTP nhận được',
      styleInformation: BigTextStyleInformation(''),
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.message,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);
    final notificationId =
        (DateTime.now().millisecondsSinceEpoch % 100000).toInt();

    try {
      await _localNotifications.show(
        id: notificationId,
        title: '🔐 Mã OTP từ $sender: $otp',
        body: 'Nội dung: $rawMessage\nChạm để sao chép mã $otp',
        notificationDetails: notificationDetails,
        payload: otp,
      );
    } catch (e) {
      debugPrint('Could not trigger native local notification: $e');
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    _otpStreamController.add(
      ReceivedOtpModel(
        id: 'demo_$notificationId',
        sender: sender,
        otp: otp,
        receivedAt: now,
        expiresAt: now + (5 * 60 * 1000),
        rawMessage: rawMessage,
      ),
    );
  }

  /// Bắn thông báo demo cho tình huống: Máy A gửi OTP tới Máy B thành công.
  static Future<void> showDemoSenderSuccessNotification({
    String sender = 'Vietcombank',
    String otp = '849201',
    String targetDevice = 'Máy Nhận (Malaysia)',
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'sms_navigator_sender_channel',
      'Thông Báo Chuyển Tiếp',
      channelDescription: 'Thông báo trạng thái chuyển tiếp OTP thành công',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'Chuyển tiếp OTP thành công',
      styleInformation: BigTextStyleInformation(''),
      playSound: true,
      enableVibration: true,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);
    final notificationId =
        (DateTime.now().millisecondsSinceEpoch % 100000).toInt();

    try {
      await _localNotifications.show(
        id: notificationId,
        title: '✅ Đã Chuyển Tiếp OTP Thành Công',
        body: 'Đã gửi mã $otp (từ $sender) tới $targetDevice qua kênh E2EE',
        notificationDetails: notificationDetails,
        payload: otp,
      );
    } catch (e) {
      debugPrint('Could not trigger native local notification: $e');
    }
  }
}

import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:vynx/config/api_urls.dart';
import 'package:vynx/pages/contacts/contacts_controller.dart';
import 'package:vynx/routes/app_routes.dart';
import 'package:vynx/services/api_service.dart';
import 'package:vynx/services/storage_service.dart';
import 'package:vynx/services/token_service.dart';

class PushNotificationService extends GetxService {
  final Dio _dio = Get.find<ApiService>().dio;
  final StorageService _storage = Get.find<StorageService>();
  final TokenService _tokenService = Get.find<TokenService>();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onMessageOpenedSub;
  StreamSubscription<String>? _onTokenRefreshSub;
  Timer? _registerRetryTimer;
  int _registerRetryAttempts = 0;
  String? _pendingTapType;

  bool _isInitialized = false;
  bool _localInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    await _initializeLocalNotifications();

    _onMessageSub = FirebaseMessaging.onMessage.listen((message) {
      _handleIncomingMessage(message, showPopup: true);
    });

    _onMessageOpenedSub = FirebaseMessaging.onMessageOpenedApp.listen((
      message,
    ) {
      _handleIncomingMessage(message, showPopup: false);
      _queueNotificationTap(message.data['type']?.toString());
    });

    _onTokenRefreshSub = _messaging.onTokenRefresh.listen((token) {
      _storage.saveDeviceFcmToken(token);
      registerDeviceTokenIfPossible(force: true, tokenOverride: token);
    });

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleIncomingMessage(initialMessage, showPopup: false);
      _queueNotificationTap(initialMessage.data['type']?.toString());
    }

    if (Platform.isIOS || Platform.isMacOS) {
      await _waitForApnsToken();
    }

    try {
      final token = await _messaging.getToken();
      if (token != null && token.isNotEmpty) {
        _storage.saveDeviceFcmToken(token);
        await registerDeviceTokenIfPossible(tokenOverride: token);
      }
    } on FirebaseException catch (e) {
      if (e.code != 'apns-token-not-set') rethrow;
    }

    _ensureTokenRegisteredEventually();
  }

  Future<void> _initializeLocalNotifications() async {
    if (_localInitialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/launcher_icons',
    );
    const darwinSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        _queueNotificationTap(response.payload);
      },
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        'vynx_messages',
        'Vynx Notifications',
        description: 'Message and contact request notifications',
        importance: Importance.max,
      ),
    );

    _localInitialized = true;
  }

  Future<void> registerDeviceTokenIfPossible({
    bool force = false,
    String? tokenOverride,
  }) async {
    final refreshToken = await _tokenService.getRefreshToken();
    if (refreshToken == null) {
      _scheduleRegisterRetry();
      return;
    }

    if ((Platform.isIOS || Platform.isMacOS) && tokenOverride == null) {
      final apns = await _messaging.getAPNSToken();
      if (apns == null || apns.isEmpty) {
        _scheduleRegisterRetry();
        return;
      }
    }

    String? token = tokenOverride ?? _storage.getDeviceFcmToken();
    if (token == null || token.trim().isEmpty) {
      try {
        token = await _messaging.getToken();
      } on FirebaseException catch (e) {
        if (e.code == 'apns-token-not-set') {
          _scheduleRegisterRetry();
          return;
        }
        _scheduleRegisterRetry();
        return;
      } catch (_) {
        _scheduleRegisterRetry();
        return;
      }
    }

    if (token == null || token.trim().isEmpty) {
      _scheduleRegisterRetry();
      return;
    }

    final alreadyRegistered = _storage.getRegisteredDeviceFcmToken();
    if (!force && alreadyRegistered == token) {
      return;
    }

    try {
      await _dio.post(ApiUrls.usersDeviceToken, data: {'token': token});
      _storage.saveDeviceFcmToken(token);
      _storage.saveRegisteredDeviceFcmToken(token);
      debugPrint('FCM token registered on backend');
      _registerRetryAttempts = 0;
      _registerRetryTimer?.cancel();
      _registerRetryTimer = null;
    } catch (_) {
      debugPrint('FCM token register call failed, scheduling retry');
      _scheduleRegisterRetry();
    }
  }

  Future<void> _waitForApnsToken() async {
    for (int i = 0; i < 8; i++) {
      final apnsToken = await _messaging.getAPNSToken();
      if (apnsToken != null && apnsToken.isNotEmpty) return;
      await Future<void>.delayed(const Duration(milliseconds: 400));
    }
  }

  void _ensureTokenRegisteredEventually() {
    Future<void>(() async {
      for (int i = 0; i < 8; i++) {
        await registerDeviceTokenIfPossible(force: i > 0);
        final registered = _storage.getRegisteredDeviceFcmToken();
        if (registered != null && registered.isNotEmpty) return;
        await Future<void>.delayed(const Duration(seconds: 5));
      }
    });
  }

  void _scheduleRegisterRetry() {
    if (_registerRetryAttempts >= 12) return;
    if (_registerRetryTimer != null) return;

    _registerRetryAttempts += 1;
    _registerRetryTimer = Timer(const Duration(seconds: 5), () async {
      _registerRetryTimer = null;
      await registerDeviceTokenIfPossible(force: true);
    });
  }

  Future<void> unregisterDeviceTokenIfPossible() async {
    final token = _storage.getDeviceFcmToken();
    if (token == null || token.isEmpty) return;

    try {
      await _dio.delete(ApiUrls.usersDeviceToken, data: {'token': token});
      _storage.clearDeviceFcmToken();
    } catch (_) {
      // Ignore on logout path
    }
  }

  void _handleIncomingMessage(
    RemoteMessage message, {
    required bool showPopup,
  }) {
    final type = message.data['type']?.toString() ?? '';
    if (type.startsWith('contact_request')) {
      if (Get.isRegistered<ContactsController>()) {
        Get.find<ContactsController>().refreshAll();
      }
    }

    if (!showPopup) return;
    _showSystemNotification(message);
  }

  Future<void> _showSystemNotification(RemoteMessage message) async {
    final title = message.notification?.title ?? "Notification";
    final body = message.notification?.body ?? "You have a new update.";
    const androidDetails = AndroidNotificationDetails(
      'vynx_messages',
      'Vynx Notifications',
      channelDescription: 'Message and contact request notifications',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/launcher_icons',
      ticker: 'vynx',
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: message.data['type']?.toString(),
    );
  }

  void onAppReady() {
    _flushPendingTapIfPossible();
  }

  void _queueNotificationTap(String? payload) {
    final type = (payload ?? '').trim();
    // Navigate only for "received request", not accepted/rejected.
    if (type != 'contact_request_received') return;
    _pendingTapType = type;
    _flushPendingTapIfPossible();
  }

  void _flushPendingTapIfPossible() {
    if (_pendingTapType == null) return;
    // Avoid navigation before GetMaterialApp navigator is ready.
    if (Get.key.currentState == null) {
      Future<void>.delayed(
        const Duration(milliseconds: 350),
        _flushPendingTapIfPossible,
      );
      return;
    }

    _pendingTapType = null;
    if (Get.currentRoute != Routes.contacts) {
      Get.toNamed(Routes.contacts);
    }
  }

  @override
  void onClose() {
    _onMessageSub?.cancel();
    _onMessageOpenedSub?.cancel();
    _onTokenRefreshSub?.cancel();
    _registerRetryTimer?.cancel();
    super.onClose();
  }
}

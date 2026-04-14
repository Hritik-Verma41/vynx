import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:vynx/controllers/user_controller.dart';
import 'package:vynx/services/api_service.dart';
import 'package:vynx/services/app_lock_service.dart';
import 'package:vynx/services/auth_service.dart';
import 'package:vynx/services/auth_timer_service.dart';
import 'package:vynx/services/backgroud_sync_service.dart';
import 'package:vynx/services/cloudinary_service.dart';
import 'package:vynx/services/chat_socket_service.dart';
import 'package:vynx/services/push_notification_service.dart';
import 'package:vynx/services/storage_service.dart';
import 'package:vynx/services/token_service.dart';
import 'package:vynx/widgets/lock_overlay.dart';

import './routes/app_pages.dart';
import './routes/app_routes.dart';

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

Future<void> startApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await GetStorage.init();

  await Get.putAsync(() async => StorageService());
  final storage = Get.find<StorageService>();
  Get.changeThemeMode(storage.getThemeMode());

  final tokenService = Get.put(TokenService());
  await Get.putAsync(() async => ApiService());

  final authTimer = Get.put(AuthTimerService(), permanent: true);

  String? refreshToken = await tokenService.getRefreshToken();
  bool isSessionValid = false;

  if (refreshToken != null) {
    isSessionValid = await authTimer.refreshSession();

    if (isSessionValid) {
      authTimer.startTokenTimer();
    } else {
      tokenService.isUserLoggedIn = false;
    }
  }

  Get.put(AuthService(), permanent: true);
  final chatSocketService = Get.put(ChatSocketService(), permanent: true);
  final pushService = Get.put(PushNotificationService(), permanent: true);
  await Get.putAsync(() async => CloudinaryService());
  Get.put(UserController(), permanent: true);
  Get.put(BackgroudSyncService());
  Get.put(AppLockService(), permanent: true);
  await pushService.initialize();
  await chatSocketService.connect();

  runApp(MyApp(initalRoute: isSessionValid ? Routes.vynxhub : Routes.login));
  WidgetsBinding.instance.addPostFrameCallback((_) {
    pushService.onAppReady();
  });
}

class MyApp extends StatelessWidget {
  final String initalRoute;
  const MyApp({super.key, required this.initalRoute});

  @override
  Widget build(BuildContext context) {
    final storage = Get.find<StorageService>();

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Vynx',
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: storage.getThemeMode(),
      initialRoute: initalRoute,
      getPages: AppPages.routes,
      builder: (context, child) {
        final lockService = Get.find<AppLockService>();

        return Stack(
          children: [
            child!,
            Obx(() {
              if (lockService.isOverlayShowing.value) {
                return LockOverlay(onRetry: () => lockService.checkAndLock());
              }
              return const SizedBox.shrink();
            }),
          ],
        );
      },
    );
  }
}

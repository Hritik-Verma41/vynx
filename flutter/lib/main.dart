import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vynx/controllers/user_controller.dart';
import 'package:vynx/services/api_service.dart';
import 'package:vynx/services/auth_service.dart';
import 'package:vynx/services/cloudinary_service.dart';
import 'package:vynx/services/storage_service.dart';
import 'package:vynx/services/token_service.dart';

import './routes/app_pages.dart';
import './routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await Get.putAsync(() async => StorageService());
  final tokenService = Get.put(TokenService());
  String? refreshToken = await tokenService.getRefreshToken();
  await Get.putAsync(() async => ApiService());
  Get.put(AuthService(), permanent: true);
  await Get.putAsync(() async => CloudinaryService());
  Get.put(UserController(), permanent: true);

  runApp(
    MyApp(initalRoute: refreshToken != null ? Routes.vynxhub : Routes.login),
  );
}

class MyApp extends StatelessWidget {
  final String initalRoute;
  const MyApp({super.key, required this.initalRoute});

  @override
  Widget build(BuildContext context) {
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
      themeMode: ThemeMode.system,
      initialRoute: initalRoute,
      getPages: AppPages.routes,
    );
  }
}

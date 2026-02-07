import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vynx/services/token_service.dart';
import '../routes/app_routes.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final tokenService = Get.find<TokenService>();

    if (!tokenService.isUserLoggedIn) {
      return const RouteSettings(name: Routes.login);
    }
    return null;
  }
}

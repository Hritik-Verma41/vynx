import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../routes/app_routes.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    bool isLoggedIn = false;

    if (!isLoggedIn) {
      return const RouteSettings(name: Routes.login);
    }
  }
}

import 'package:get/get.dart';
import 'package:vynx/middlewares/auth_middleware.dart';
import 'package:vynx/pages/login/login_page.dart';
import 'package:vynx/pages/signup/otp/otp_page.dart';
import 'package:vynx/pages/signup/setup_on_signup/setup_on_signup_page.dart';
import 'package:vynx/pages/signup/signup_page.dart';
import 'package:vynx/pages/vynx_hub/vynx_hub_page.dart';
import 'app_routes.dart';

class AppPages {
  static final routes = [
    // chats page
    GetPage(
      name: Routes.vynxhub,
      page: () => const VynxHubPage(),
      middlewares: [AuthMiddleware()],
    ),
    // login page
    GetPage(name: Routes.login, page: () => const LoginPage()),
    // otp page
    GetPage(name: '/otp-page', page: () => const OtpPage()),
    // setup on signup page
    GetPage(name: Routes.setupOnSignUp, page: () => SetupOnSignupPage()),
    // signup page
    GetPage(name: Routes.signup, page: () => const SignUpPage()),
  ];
}

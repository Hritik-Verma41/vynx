import 'package:get/get.dart';
import 'package:vynx/middlewares/auth_middleware.dart';
import 'package:vynx/pages/login/login_page.dart';
import 'package:vynx/pages/settings/account_info/account_info_page.dart';
import 'package:vynx/pages/settings/account_info/account_info_controller.dart';
import 'package:vynx/pages/settings/appearance/appearance_page.dart';
import 'package:vynx/pages/settings/notifications/notifications_settings_controller.dart';
import 'package:vynx/pages/settings/notifications/notifications_settings_page.dart';
import 'package:vynx/pages/settings/privacy_settings/privacy_settings_page.dart';
import 'package:vynx/pages/settings/privacy_settings/privacy_settings_controller.dart';
import 'package:vynx/pages/settings/security_settings/security_settings_page.dart';
import 'package:vynx/pages/settings/security_settings/security_settings_controller.dart';
import 'package:vynx/pages/signup/otp/otp_page.dart';
import 'package:vynx/pages/signup/otp/otp_ctrl.dart';
import 'package:vynx/pages/signup/setup_on_signup/setup_on_signup_page.dart';
import 'package:vynx/pages/signup/setup_on_signup/setup_on_signup_ctrl.dart';
import 'package:vynx/pages/signup/signup_page.dart';
import 'package:vynx/pages/vynx_hub/vynx_hub_page.dart';
import 'package:vynx/pages/vynx_hub/vynx_hub_contoller.dart';
import 'app_routes.dart';

class AppPages {
  static final routes = [
    GetPage(
      name: Routes.vynxhub,
      page: () => const VynxHubPage(),
      middlewares: [AuthMiddleware()],
      binding: BindingsBuilder(() {
        Get.lazyPut<VynxHubController>(() => VynxHubController());
      }),
    ),
    GetPage(name: Routes.login, page: () => const LoginPage()),
    GetPage(
      name: Routes.settingsNotificaions,
      page: () => NotificationsSettingsPage(),
      middlewares: [AuthMiddleware()],
      binding: BindingsBuilder(() {
        Get.lazyPut<NotificationsSettingsController>(
          () => NotificationsSettingsController(),
        );
      }),
    ),
    GetPage(
      name: Routes.otpPage,
      page: () => const OtpPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<OtpCtrl>(() => OtpCtrl());
      }),
    ),
    GetPage(
      name: Routes.privacySettings,
      page: () => PrivacySettingsPage(),
      middlewares: [AuthMiddleware()],
      binding: BindingsBuilder(() {
        Get.lazyPut<PrivacySettingsController>(
          () => PrivacySettingsController(),
        );
      }),
    ),
    GetPage(
      name: Routes.settingsSecurity,
      page: () => SecuritySettingsPage(),
      middlewares: [AuthMiddleware()],
      binding: BindingsBuilder(() {
        Get.lazyPut<SecuritySettingsController>(
          () => SecuritySettingsController(),
        );
      }),
    ),
    GetPage(
      name: Routes.setupOnSignUp,
      page: () => SetupOnSignupPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<SetupOnSignupCtrl>(() => SetupOnSignupCtrl());
      }),
    ),
    GetPage(
      name: Routes.settingsAccountInfo,
      page: () => AccountInfoPage(),
      middlewares: [AuthMiddleware()],
      binding: BindingsBuilder(() {
        Get.lazyPut<AccountInfoController>(() => AccountInfoController());
      }),
    ),
    GetPage(
      name: Routes.settingsAppearance,
      page: () => AppearancePage(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(name: Routes.signup, page: () => const SignUpPage()),
  ];
}

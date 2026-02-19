import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';
import 'package:vynx/services/storage_service.dart';

class SecuritySettingsController extends GetxController {
  final LocalAuthentication auth = LocalAuthentication();
  final StorageService _storage = Get.find<StorageService>();

  var isAppLockEnabled = false.obs;

  @override
  void onInit() {
    super.onInit();
    isAppLockEnabled.value = _storage.getAppLockEnabled();
  }

  Future<void> toggleAppLock(bool value) async {
    if (value) {
      bool authenticated = await _authenticate();
      if (authenticated) {
        isAppLockEnabled.value = true;
        _storage.saveAppLoackEnabled(true);
      }
    } else {
      bool authenticated = await _authenticate();
      if (authenticated) {
        isAppLockEnabled.value = false;
        _storage.saveAppLoackEnabled(false);
      }
    }
  }

  Future<bool> _authenticate() async {
    try {
      return await auth.authenticate(
        localizedReason: 'Please authenticate to secure Vynx',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } catch (e) {
      return false;
    }
  }
}

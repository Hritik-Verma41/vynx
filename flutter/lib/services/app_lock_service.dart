import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';
import 'package:vynx/services/storage_service.dart';

class AppLockService extends GetxService with WidgetsBindingObserver {
  final LocalAuthentication _auth = LocalAuthentication();
  final StorageService _storage = Get.find<StorageService>();

  bool _isAuthenticating = false;
  bool _isUnlocked = false;

  var isOverlayShowing = false.obs;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    checkAndLock();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final isLockEnabled = _storage.getAppLockEnabled();

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (isLockEnabled) {
        _isUnlocked = false;
        isOverlayShowing.value = true;
      } else {
        isOverlayShowing.value = false;
      }
    }

    if (state == AppLifecycleState.resumed && !_isUnlocked) {
      if (isLockEnabled) {
        debugPrint("App Resumed: Checking Lock...");
        checkAndLock();
      } else {
        isOverlayShowing.value = false;
        _isUnlocked = true;
      }
    }
  }

  Future<void> checkAndLock() async {
    final bool isLockEnabled = _storage.getAppLockEnabled();

    if (!isLockEnabled || _isUnlocked) return;

    if (!_isAuthenticating) {
      _isAuthenticating = true;

      bool authenticated = await _authenticate();

      if (authenticated) {
        _isUnlocked = true;
        isOverlayShowing.value = false;
        _isAuthenticating = false;
      } else {
        _isAuthenticating = false;
      }
    }
  }

  Future<bool> _authenticate() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _auth.isDeviceSupported();

      if (!canAuthenticate) return true;

      return await _auth.authenticate(
        localizedReason: 'Vynx is locked. Please authenticate to continue.',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
          useErrorDialogs: true,
        ),
      );
    } catch (e) {
      debugPrint("Auth Error: $e");
      return false;
    }
  }
}

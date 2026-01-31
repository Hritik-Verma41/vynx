import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vynx/services/auth_service.dart';

class LoginCtrl extends GetxController {
  final AuthService _auth = Get.find<AuthService>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  var isLoading = false.obs;

  Future<void> loginWithGoogle() async {
    isLoading.value = true;
    final userCredential = await _auth.signInWithGoogle();
    isLoading.value = false;

    if (userCredential != null) {
      final user = userCredential.user;
      debugPrint("==== GOOGLE USER DATA ====");
      debugPrint("Name: ${user?.displayName}");
      debugPrint("Email: ${user?.email}");
      debugPrint("Photo URL: ${user?.photoURL}");
      debugPrint("UID: ${user?.uid}");

      _showDataSnackbar("Google Data", user?.email ?? "No Email Found");
    }
  }

  Future<void> loginWithFacebook() async {
    isLoading.value = true;
    final userCredential = await _auth.signInWithFacebook();
    isLoading.value = false;

    if (userCredential != null) {
      final user = userCredential.user;
      debugPrint("==== FACEBOOK USER DATA ====");
      debugPrint("Name: ${user?.displayName}");
      debugPrint("Email: ${user?.email}");
      debugPrint("UID: ${user?.uid}");

      _showDataSnackbar("Facebook Data", user?.email ?? "No Email Found");
    }
  }

  void login() {
    debugPrint("Email Login Pressed: ${emailController.text}");
    _showDataSnackbar("Local Login", "Email: ${emailController.text}");
  }

  void _showDataSnackbar(String title, String message) {
    Get.snackbar(
      title,
      "User: $message",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.withValues(alpha: 0.1),
      colorText: Colors.green,
      duration: const Duration(seconds: 5),
    );
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}

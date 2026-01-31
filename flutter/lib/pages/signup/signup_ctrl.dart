import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/auth_service.dart';

class SignupCtrl extends GetxController {
  final AuthService _auth = Get.find<AuthService>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  var isLoading = false.obs;

  Future<void> signupWithGoogle() async {
    isLoading.value = true;
    final userCredential = await _auth.signInWithGoogle();
    isLoading.value = false;

    if (userCredential != null) {
      final user = userCredential.user;
      debugPrint("==== GOOGLE SIGNUP DATA ====");
      debugPrint("Name: ${user?.displayName}");
      debugPrint("Email: ${user?.email}");
      debugPrint("UID: ${user?.uid}");

      _showDataSnackbar("Google Signup Data", user?.email ?? "No Email");
    }
  }

  Future<void> signupWithFacebook() async {
    isLoading.value = true;
    final userCredential = await _auth.signInWithFacebook();
    isLoading.value = false;

    if (userCredential != null) {
      final user = userCredential.user;
      debugPrint("==== FACEBOOK SIGNUP DATA ====");
      debugPrint("Name: ${user?.displayName}");
      debugPrint("Email: ${user?.email}");
      debugPrint("UID: ${user?.uid}");

      _showDataSnackbar("Facebook Signup Data", user?.email ?? "No Email");
    }
  }

  void signup() {
    debugPrint("==== MANUAL SIGNUP DATA ====");
    debugPrint("Name: ${nameController.text}");
    debugPrint("Email: ${emailController.text}");
    _showDataSnackbar("Local Signup", "Name: ${nameController.text}");
  }

  void _showDataSnackbar(String title, String message) {
    Get.snackbar(
      title,
      "User: $message",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.purple.withValues(alpha: 0.1),
      colorText: Colors.purple,
      duration: const Duration(seconds: 5),
    );
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}

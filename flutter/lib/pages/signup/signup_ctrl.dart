import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vynx/routes/app_routes.dart';
import '../../services/auth_service.dart';

class SignupCtrl extends GetxController {
  final AuthService _auth = Get.find<AuthService>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  var isLoading = false.obs;

  // Track if user has interacted with the name field
  var hasInteractedWithName = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Monitor name field to trigger validation visibility in real-time
    nameController.addListener(() {
      if (nameController.text.isNotEmpty || hasInteractedWithName.value) {
        hasInteractedWithName.value = true;
      }
      update(); // Notifies GetBuilder/View to refresh validation state
    });
  }

  void _proceedToSetup({
    required String fullName,
    required String email,
    String? image,
    String? gId,
    String? fbId,
    required String provider,
    String? password,
  }) {
    List<String> parts = fullName.trim().split(' ');
    String firstName = parts.isNotEmpty ? parts[0] : "";
    String lastName = parts.length > 1 ? parts.sublist(1).join(' ') : "";

    Get.toNamed(
      Routes.setupOnSignUp,
      arguments: {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'profileImage': image,
        'googleId': gId,
        'facebookId': fbId,
        'authProvider': provider,
        'password': password,
      },
    );
  }

  Future<void> signupWithGoogle() async {
    isLoading.value = true;
    try {
      final userCredential = await _auth.signInWithGoogle();
      if (userCredential != null) {
        final user = userCredential.user;
        _proceedToSetup(
          fullName: user?.displayName ?? "New User",
          email: user?.email ?? "",
          image: user?.photoURL,
          gId: user?.uid,
          provider: 'google',
        );
      }
    } catch (e) {
      Get.snackbar("Error", "Google Sign-Up failed");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signupWithFacebook() async {
    isLoading.value = true;
    try {
      final userCredential = await _auth.signInWithFacebook();
      if (userCredential != null) {
        final user = userCredential.user;
        _proceedToSetup(
          fullName: user?.displayName ?? "New User",
          email: user?.email ?? "",
          image: user?.photoURL,
          fbId: user?.uid,
          provider: 'facebook',
        );
      }
    } catch (e) {
      Get.snackbar("Error", "Facebook Sign-Up failed");
    } finally {
      isLoading.value = false;
    }
  }

  void signup() {
    hasInteractedWithName.value = true;
    update();

    if (nameController.text.trim().isEmpty) return;

    _proceedToSetup(
      fullName: nameController.text,
      email: emailController.text,
      password: passwordController.text,
      provider: 'local',
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

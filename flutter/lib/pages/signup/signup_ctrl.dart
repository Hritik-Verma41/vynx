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
  var hasInteractedWithName = false.obs;

  @override
  void onInit() {
    super.onInit();
    nameController.addListener(() {
      if (nameController.text.isNotEmpty || hasInteractedWithName.value) {
        hasInteractedWithName.value = true;
      }
      update();
    });
  }

  void _proceedToSetup({
    required String firstName,
    required String lastName,
    required String email,
    String? image,
    String? gId,
    String? fbId,
    required String provider,
    String? password,
  }) {
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
        final userData = _auth.getUserData(userCredential);

        _proceedToSetup(
          firstName: userData['firstName'],
          lastName: userData['lastName'],
          email: userData['email'] ?? "",
          image: userData['photoUrl'],
          gId: userData['uid'],
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
        final userData = _auth.getUserData(userCredential);

        _proceedToSetup(
          firstName: userData['firstName'],
          lastName: userData['lastName'],
          email: userData['email'] ?? "",
          image: userData['photoUrl'],
          fbId: userData['uid'],
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

    List<String> parts = nameController.text.trim().split(RegExp(r'\s+'));
    String fName = parts.isNotEmpty ? parts[0] : "";
    String lName = parts.length > 1 ? parts.sublist(1).join(' ') : "";

    _proceedToSetup(
      firstName: fName,
      lastName: lName,
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

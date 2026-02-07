import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vynx/routes/app_routes.dart';
import 'package:vynx/services/api_service.dart';
import 'package:vynx/services/auth_service.dart';

class LoginCtrl extends GetxController {
  final AuthService _auth = Get.find<AuthService>();
  final Dio _dio = Get.find<ApiService>().dio;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  var hasInteractedWithEmail = false.obs;
  var hasInteractedWithPassword = false.obs;
  var isLoading = false.obs;

  var serverError = "".obs;

  @override
  void onInit() {
    super.onInit();

    emailController.addListener(() {
      if (emailController.text.isNotEmpty) hasInteractedWithEmail.value = true;
      if (serverError.value.isNotEmpty) serverError.value = "";
    });

    passwordController.addListener(() {
      if (passwordController.text.isNotEmpty)
        hasInteractedWithPassword.value = true;
      if (serverError.value.isNotEmpty) serverError.value = "";
    });
  }

  Future<void> _handleBackendLogin(Map<String, dynamic> payload) async {
    try {
      isLoading.value = true;
      serverError.value = "";

      final response = await _dio.post('/auth/login', data: payload);

      if (response.statusCode == 200) {
        Get.offAllNamed(Routes.vynxhub);
      }
    } on DioException catch (e) {
      serverError.value =
          e.response?.data['message'] ?? "Login failed. Please try again.";
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loginWithGoogle() async {
    isLoading.value = true;
    final userCredential = await _auth.signInWithGoogle();
    if (userCredential != null) {
      await _handleBackendLogin({
        'provider': 'google',
        'googleUid': userCredential.user?.uid,
      });
    } else {
      isLoading.value = false;
    }
  }

  Future<void> loginWithFacebook() async {
    isLoading.value = true;
    final userCredential = await _auth.signInWithFacebook();
    if (userCredential != null) {
      await _handleBackendLogin({
        'provider': 'facebook',
        'facebookUid': userCredential.user?.uid,
      });
    } else {
      isLoading.value = false;
    }
  }

  void login() async {
    await _handleBackendLogin({
      'provider': 'local',
      'email': emailController.text.trim(),
      'password': passwordController.text,
    });
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}

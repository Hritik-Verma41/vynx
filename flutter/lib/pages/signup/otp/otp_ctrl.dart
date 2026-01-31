import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import 'package:vynx/pages/signup/setup_on_signup/setup_on_signup_ctrl.dart';
import 'package:vynx/routes/app_routes.dart';

class OtpCtrl extends GetxController {
  final setupCtrl = Get.find<SetupOnSignupCtrl>();
  final otpController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  var timerCount = 60.obs;
  var canResend = false.obs;
  var otpError = "".obs;
  Timer? _timer;

  @override
  void onInit() {
    startTimer();
    super.onInit();
  }

  void startTimer() {
    canResend.value = false;
    timerCount.value = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timerCount.value > 0) {
        timerCount.value--;
      } else {
        canResend.value = true;
        _timer?.cancel();
      }
    });
  }

  void resendOtp() {
    if (canResend.value) {
      otpError.value = "";
      setupCtrl.startPhoneVerification();
      startTimer();
    }
  }

  Future<void> verifyAndRegister() async {
    String code = otpController.text.trim();
    if (code.length != 6) {
      otpError.value = "Please enter the 6-digit code.";
      return;
    }

    otpError.value = "";
    setupCtrl.isLoading.value = true;

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: setupCtrl.verificationIdValue,
        smsCode: code,
      );

      // Let completeWithCredential handle the sign-in and backend flow
      await completeWithCredential(credential);
    } catch (e) {
      setupCtrl.isLoading.value = false;
      debugPrint("VerifyAndRegister top-level catch: $e");
    }
  }

  Future<void> completeWithCredential(PhoneAuthCredential credential) async {
    try {
      // 1. Firebase Sign In
      UserCredential userCred = await _auth.signInWithCredential(credential);
      String? uid = userCred.user?.uid;

      if (uid != null) {
        // 2. Backend API Call (defined in SetupCtrl)
        await setupCtrl.callBackendApi(uid);
        Get.offAllNamed(Routes.chat);
      }
    } on FirebaseAuthException catch (e) {
      setupCtrl.isLoading.value = false;
      debugPrint("Firebase Auth Code: ${e.code}");

      // Handle incorrect OTP specifically
      if (e.code == 'invalid-verification-code') {
        otpError.value = "The code is incorrect. Please try again.";
      } else if (e.code == 'session-expired') {
        otpError.value = "OTP expired. Please click resend.";
      } else {
        otpError.value = e.message ?? "Verification failed.";
      }
    } on DioException catch (de) {
      setupCtrl.isLoading.value = false;
      otpError.value =
          de.response?.data['message'] ?? "Server connection failed.";
    } catch (e) {
      setupCtrl.isLoading.value = false;
      debugPrint("Generic Registration Error: $e");
      otpError.value = "Error during final registration: $e";
    }
  }

  @override
  void onClose() {
    _timer?.cancel();
    otpController.dispose();
    super.onClose();
  }
}

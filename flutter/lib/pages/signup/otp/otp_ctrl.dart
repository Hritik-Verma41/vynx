import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:vynx/pages/signup/setup_on_signup/setup_on_signup_ctrl.dart';
import 'package:vynx/services/api_service.dart';
import 'package:vynx/routes/app_routes.dart';

class OtpCtrl extends GetxController {
  final setupCtrl = Get.find<SetupOnSignupCtrl>();
  final otpController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Dio _dio = Get.find<ApiService>().dio;

  var currentOtpLength = 0.obs;
  var timerCount = 60.obs;
  var canResend = false.obs;
  var otpError = "".obs;
  Timer? _timer;

  @override
  void onInit() {
    startTimer();
    super.onInit();
  }

  // --- Timer & Resend Logic ---

  void startTimer() {
    canResend.value = false;
    timerCount.value = 60;
    _timer?.cancel();
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
      setupCtrl.startPhoneVerification(); // Re-triggers Firebase SMS
      startTimer();
    }
  }

  void onOtpChanged(String val) {
    currentOtpLength.value = val.length;
    if (otpError.value.isNotEmpty) otpError.value = "";
  }

  // --- Verification Logic ---

  Future<void> verifyAndRegister() async {
    String code = otpController.text.trim();
    if (code.length != 6) return;

    otpError.value = "";
    setupCtrl.isLoading.value = true;

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: setupCtrl.verificationIdValue,
        smsCode: code,
      );
      await completeWithCredential(credential);
    } catch (e) {
      log("Verification Error: $e");
      otpError.value = "Invalid verification code.";
      setupCtrl.isLoading.value = false;
    }
  }

  Future<void> completeWithCredential(PhoneAuthCredential credential) async {
    try {
      // 1. Firebase Sign-in
      UserCredential userCred = await _auth.signInWithCredential(credential);
      String? uid = userCred.user?.uid;

      if (uid != null) {
        // 2. Call Backend (Image processing happens here)
        await _callBackendApi(uid);

        // 3. Success -> Final Navigation
        Get.offAllNamed(Routes.chat);
      }
    } catch (e) {
      log("Auth/Backend Flow Error: $e");
      otpError.value = "Registration failed. Please try again.";
    } finally {
      // SAFETY: If an error happened or the API timed out,
      // we must reset the loading state so the user isn't stuck.
      if (Get.currentRoute == Routes.otpPage) {
        setupCtrl.isLoading.value = false;
      }
    }
  }

  Future<void> _callBackendApi(String firebaseUid) async {
    // Process image (Local, Network, or Asset)
    String profileImageData = await _processImageHelper();

    final payload = {
      'firstName': setupCtrl.firstNameController.text.trim(),
      'lastName': setupCtrl.lastNameController.text.trim(),
      'email': setupCtrl.data?['email'],
      'phoneNumber': setupCtrl.completePhoneNumber.value,
      'profileImage': profileImageData,
      'gender': setupCtrl.selectedGender.value,
      'firebaseUid': firebaseUid,
      'password': setupCtrl.data?['password'],
      'googleUid': setupCtrl.data?['googleId'],
      'facebookUid': setupCtrl.data?['facebookId'],
      'providers': _getProvidersList(),
    };

    try {
      // POST to Node.js backend
      await _dio.post('/auth/sign-up', data: payload);
    } on DioException catch (e) {
      log("Backend Dio Error: ${e.message}");
      rethrow; // Pass to parent catch-finally
    }
  }

  // --- Image Processing Helpers ---

  Future<String> _processImageHelper() async {
    try {
      // Case A: Gallery Image
      if (setupCtrl.selectedImagePath.value.isNotEmpty) {
        return base64Encode(
          await File(setupCtrl.selectedImagePath.value).readAsBytes(),
        );
      }

      // Case B: Social URL (Download)
      if (setupCtrl.socialImageUrl.value.isNotEmpty) {
        final res = await http
            .get(Uri.parse(setupCtrl.socialImageUrl.value))
            .timeout(const Duration(seconds: 5));
        if (res.statusCode == 200) return base64Encode(res.bodyBytes);
      }

      // Case C: Local Asset (Avatar)
      return await _loadAssetAsBase64();
    } catch (e) {
      log("Image process error: $e. Using asset fallback.");
      return await _loadAssetAsBase64();
    }
  }

  Future<String> _loadAssetAsBase64() async {
    try {
      String assetName = setupCtrl.selectedDefaultImage.value.trim();
      if (assetName.isEmpty) assetName = "default-profile-male-1.png";

      final data = await rootBundle.load('assets/images/$assetName');
      return base64Encode(data.buffer.asUint8List());
    } catch (e) {
      log("Asset missing: $e. Returning empty string to avoid hang.");
      return "";
    }
  }

  List<String> _getProvidersList() {
    List<String> p = ['phone'];
    if (setupCtrl.data?['password'] != null) p.add('local');
    if (setupCtrl.data?['googleId'] != null) p.add('google');
    if (setupCtrl.data?['facebookId'] != null) p.add('facebook');
    return p;
  }

  @override
  void onClose() {
    _timer?.cancel();
    otpController.dispose();
    super.onClose();
  }
}

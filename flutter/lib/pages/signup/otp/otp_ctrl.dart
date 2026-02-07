import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Response;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import 'package:vynx/controllers/user_controller.dart';
import 'package:vynx/pages/signup/setup_on_signup/setup_on_signup_ctrl.dart';
import 'package:vynx/services/api_service.dart';
import 'package:vynx/services/cloudinary_service.dart';
import 'package:vynx/routes/app_routes.dart';
import 'package:vynx/services/token_service.dart';

class OtpCtrl extends GetxController {
  final setupCtrl = Get.find<SetupOnSignupCtrl>();
  final _cloudinary = Get.find<CloudinaryService>();
  final tokenService = Get.find<TokenService>();
  final userCtrl = Get.put(UserController());
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
      setupCtrl.startPhoneVerification();
      startTimer();
    }
  }

  void onOtpChanged(String val) {
    currentOtpLength.value = val.length;
    if (otpError.value.isNotEmpty) otpError.value = "";
  }

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
      UserCredential userCred = await _auth.signInWithCredential(credential);
      String? uid = userCred.user?.uid;

      if (uid != null) {
        final response = await _callBackendApi(uid);

        if (response != null &&
            (response.statusCode == 200 || response.statusCode == 201)) {
          final access = response.headers
              .value('Authorization')
              ?.replaceAll('Bearer ', '');
          final refresh = response.headers.value('x-refresh-token');

          if (access != null && refresh != null) {
            await tokenService.saveTokens(access, refresh);
            await userCtrl.fetchProfile();

            Get.offAllNamed(Routes.vynxhub);
          } else {
            log("Signup success but tokens missing in headers");
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      otpError.value = e.code == 'invalid-verification-code'
          ? "Invalid OTP. Please check and try again."
          : "Auth error: ${e.message}";
    } catch (e) {
      String errorMessage = "Registration failed. Please try again.";

      if (e is DioException) {
        errorMessage = e.response?.data['message'] ?? "Backend error occurred.";
        log("Backend Flow Error: $errorMessage");
      } else {
        errorMessage = e.toString();
        log("System Error: $errorMessage");
      }

      otpError.value = errorMessage;
    } finally {
      setupCtrl.isLoading.value = false;
    }
  }

  Future<Response?> _callBackendApi(String firebaseUid) async {
    final cloudinaryData = await _getCloudinaryData();

    if (cloudinaryData == null) {
      throw Exception("Failed to upload profile image.");
    }

    final String profileImageUrl = cloudinaryData['url']!;
    final String publicId = cloudinaryData['public_id']!;

    final payload = {
      'firstName': setupCtrl.firstNameController.text.trim(),
      'lastName': setupCtrl.lastNameController.text.trim(),
      'email': setupCtrl.data?['email'],
      'phoneNumber': setupCtrl.completePhoneNumber.value,
      'profileImage': profileImageUrl,
      'gender': setupCtrl.selectedGender.value,
      'firebaseUid': firebaseUid,
      'password': setupCtrl.data?['password'],
      'googleUid': setupCtrl.data?['googleId'],
      'facebookUid': setupCtrl.data?['facebookId'],
      'providers': _getProvidersList(),
    };

    try {
      return await _dio.post('/auth/sign-up', data: payload);
    } on DioException catch (e) {
      final cleanMessage = e.response?.data['message'] ?? "Signup failed";

      log("Registration Blocked: $cleanMessage");

      await _cloudinary.deleteImage(publicId);
      rethrow;
    }
  }

  Future<Map<String, String>?> _getCloudinaryData() async {
    try {
      if (setupCtrl.selectedImagePath.value.isNotEmpty) {
        return await _cloudinary.uploadImage(
          filePath: setupCtrl.selectedImagePath.value,
        );
      }

      if (setupCtrl.socialImageUrl.value.isNotEmpty) {
        return await _cloudinary.uploadImage(
          networkUrl: setupCtrl.socialImageUrl.value,
        );
      }

      String assetName = setupCtrl.selectedDefaultImage.value.isEmpty
          ? "default-profile-male-1.png"
          : setupCtrl.selectedDefaultImage.value;

      final byteData = await rootBundle.load('assets/images/$assetName');
      return await _cloudinary.uploadImage(
        assetBytes: byteData.buffer.asUint8List(),
        assetName: assetName,
      );
    } catch (e) {
      log("Cloudinary Step Error: $e");
      return null;
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

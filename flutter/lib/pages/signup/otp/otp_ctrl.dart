import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Response;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import 'package:vynx/config/api_urls.dart';
import 'package:vynx/controllers/user_controller.dart';
import 'package:vynx/pages/settings/account_info/account_info_controller.dart';
import 'package:vynx/pages/signup/setup_on_signup/setup_on_signup_ctrl.dart';
import 'package:vynx/services/api_service.dart';
import 'package:vynx/services/cloudinary_service.dart';
import 'package:vynx/routes/app_routes.dart';
import 'package:vynx/services/token_service.dart';

class OtpCtrl extends GetxController {
  SetupOnSignupCtrl? get setupCtrl => Get.isRegistered<SetupOnSignupCtrl>()
      ? Get.find<SetupOnSignupCtrl>()
      : null;

  AccountInfoController? get accountCtrl =>
      Get.isRegistered<AccountInfoController>()
      ? Get.find<AccountInfoController>()
      : null;

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
      if (accountCtrl != null) {
        accountCtrl!.startPhoneVerification();
      } else {
        setupCtrl?.startPhoneVerification();
      }
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

    final args = Get.arguments;
    final bool isUpdateMode = args != null && args['isUpdate'] == true;

    otpError.value = "";

    if (isUpdateMode) {
      accountCtrl?.isLoading.value = true;
    } else {
      setupCtrl?.isLoading.value = true;
    }

    try {
      String activeVerificationId = isUpdateMode
          ? (accountCtrl?.verificationId ?? "")
          : (setupCtrl?.verificationIdValue ?? "");

      final credential = PhoneAuthProvider.credential(
        verificationId: activeVerificationId,
        smsCode: code,
      );

      await _auth.signInWithCredential(credential);

      if (isUpdateMode) {
        await _handleProfileUpdate(args['payload']);
      } else {
        await completeWithCredential(credential);
      }
    } catch (e) {
      log("Verification Error: $e");
      otpError.value = "Invalid verification code.";

      if (isUpdateMode) {
        accountCtrl?.isLoading.value = false;
      } else {
        setupCtrl?.isLoading.value = false;
      }
    }
  }

  Future<void> _handleProfileUpdate(Map<String, dynamic> payload) async {
    try {
      final String? oldImageUrl = userCtrl.user.value?.profileImage;
      bool hasNewImageUploaded = false;

      if (payload['profileImage'] == "upload" && accountCtrl != null) {
        final cloudRes = await _cloudinary.uploadImage(
          filePath: accountCtrl!.selectedImagePath.value,
        );
        payload['profileImage'] = cloudRes?['url'];
        hasNewImageUploaded = true;
      } else if (payload['profileImage'].toString().contains(
        'default-profile',
      )) {
        final String assetName = payload['profileImage'];
        final byteData = await rootBundle.load('assets/images/$assetName');

        final cloudRes = await _cloudinary.uploadImage(
          assetBytes: byteData.buffer.asUint8List(),
          assetName: assetName,
        );
        payload['profileImage'] = cloudRes?['url'];
        hasNewImageUploaded = true;
      }

      final response = await _dio.patch(ApiUrls.updateProfile, data: payload);

      if (response.statusCode == 200) {
        if (hasNewImageUploaded && oldImageUrl != null) {
          final oldPublicId = _cloudinary.getPublicIdFromUrl(oldImageUrl);
          if (oldPublicId != null) {
            _cloudinary.deleteImage(oldPublicId);
          }
        }

        await userCtrl.fetchProfile();
        Get.close(2);
        Get.snackbar(
          "Success",
          "Account updated successfully",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withValues(alpha: 0.8),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      log("Profile Update API Error: $e");
      otpError.value = "Failed to update profile on server.";
    } finally {
      accountCtrl?.isLoading.value = false;
    }
  }

  Future<void> completeWithCredential(PhoneAuthCredential credential) async {
    if (setupCtrl == null) return;

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
            log("Tokens missing in response headers");
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      otpError.value = e.code == 'invalid-verification-code'
          ? "Invalid OTP. Please check and try again."
          : "Auth error: ${e.message}";
    } catch (e) {
      log("Signup Error: $e");
      otpError.value = "Registration failed. Please try again.";
    } finally {
      setupCtrl?.isLoading.value = false;
    }
  }

  Future<Response?> _callBackendApi(String firebaseUid) async {
    if (setupCtrl == null) return null;

    final cloudinaryData = await _getCloudinaryData();
    if (cloudinaryData == null) {
      throw Exception("Failed to upload profile image.");
    }

    final String profileImageUrl = cloudinaryData['url']!;
    final String publicId = cloudinaryData['public_id']!;

    final payload = {
      'firstName': setupCtrl!.firstNameController.text.trim(),
      'lastName': setupCtrl!.lastNameController.text.trim(),
      'email': setupCtrl!.data?['email'],
      'phoneNumber': setupCtrl!.completePhoneNumber.value,
      'profileImage': profileImageUrl,
      'gender': setupCtrl!.selectedGender.value,
      'firebaseUid': firebaseUid,
      'password': setupCtrl!.data?['password'],
      'googleUid': setupCtrl!.data?['googleId'],
      'facebookUid': setupCtrl!.data?['facebookId'],
      'providers': _getProvidersList(),
    };

    try {
      return await _dio.post(ApiUrls.authSignup, data: payload);
    } on DioException catch (e) {
      log('Error caught during signup: $e');
      await _cloudinary.deleteImage(publicId);
      rethrow;
    }
  }

  Future<Map<String, String>?> _getCloudinaryData() async {
    if (setupCtrl == null) return null;
    try {
      if (setupCtrl!.selectedImagePath.value.isNotEmpty) {
        return await _cloudinary.uploadImage(
          filePath: setupCtrl!.selectedImagePath.value,
        );
      }
      if (setupCtrl!.socialImageUrl.value.isNotEmpty) {
        return await _cloudinary.uploadImage(
          networkUrl: setupCtrl!.socialImageUrl.value,
        );
      }

      String assetName = setupCtrl!.selectedDefaultImage.value.isEmpty
          ? "default-profile-male-1.png"
          : setupCtrl!.selectedDefaultImage.value;

      final byteData = await rootBundle.load('assets/images/$assetName');
      return await _cloudinary.uploadImage(
        assetBytes: byteData.buffer.asUint8List(),
        assetName: assetName,
      );
    } catch (e) {
      log("Cloudinary Error: $e");
      return null;
    }
  }

  List<String> _getProvidersList() {
    List<String> p = ['phone'];
    if (setupCtrl?.data?['password'] != null) p.add('local');
    if (setupCtrl?.data?['googleId'] != null) p.add('google');
    if (setupCtrl?.data?['facebookId'] != null) p.add('facebook');
    return p;
  }

  @override
  void onClose() {
    _timer?.cancel();
    otpController.dispose();
    super.onClose();
  }
}

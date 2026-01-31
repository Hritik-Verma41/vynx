import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vynx/routes/app_routes.dart';
import 'package:vynx/pages/signup/otp/otp_ctrl.dart'; // Ensure this path is correct

class SetupOnSignupCtrl extends GetxController {
  final data = Get.arguments;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Text Controllers
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final phoneController = TextEditingController();
  final nameFocusNode = FocusNode();

  // Observables
  var selectedImagePath = "".obs;
  var socialImageUrl = "".obs;
  var isLoading = false.obs;
  final ImagePicker _picker = ImagePicker();

  var selectedGender = "male".obs;
  var selectedDefaultImage = "".obs;

  var isPhoneValid = false.obs;
  var completePhoneNumber = "".obs;
  var phoneLength = 0.obs;
  var hasInteractedWithName = false.obs;

  String _verificationId = "";
  String get verificationIdValue => _verificationId;

  @override
  void onInit() {
    firstNameController.text = data?['firstName'] ?? "";
    lastNameController.text = data?['lastName'] ?? "";
    _initializeImage();
    super.onInit();
  }

  void _initializeImage() {
    String? incomingImage = data?['profileImage'] ?? data?['photoUrl'];
    if (incomingImage != null &&
        incomingImage.isNotEmpty &&
        incomingImage.startsWith('http')) {
      socialImageUrl.value = incomingImage;
    } else {
      setRandomDefaultImage();
    }
  }

  void setGender(String gender) {
    if (selectedGender.value == gender) return;
    selectedGender.value = gender;
    if (socialImageUrl.value.isEmpty && selectedImagePath.value.isEmpty) {
      setRandomDefaultImage();
    }
  }

  void setRandomDefaultImage() {
    int randomNum = (DateTime.now().millisecondsSinceEpoch % 5) + 1;
    selectedDefaultImage.value =
        "default-profile-${selectedGender.value}-$randomNum.png";
    selectedImagePath.value = "";
    socialImageUrl.value = "";
  }

  void selectSpecificDefault(String imageName) {
    selectedDefaultImage.value = imageName;
    selectedImagePath.value = "";
    socialImageUrl.value = "";
  }

  Future<void> pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 500,
      );
      if (image != null) {
        selectedImagePath.value = image.path;
        socialImageUrl.value = "";
        selectedDefaultImage.value = "";
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to pick image");
    }
  }

  ImageProvider getProfileImage() {
    if (selectedImagePath.value.isNotEmpty) {
      return FileImage(File(selectedImagePath.value));
    }
    if (socialImageUrl.value.isNotEmpty) {
      return NetworkImage(socialImageUrl.value);
    }
    String assetPath = selectedDefaultImage.value.isEmpty
        ? 'default-profile-male-1.png'
        : selectedDefaultImage.value;
    return AssetImage('assets/images/$assetPath');
  }

  String? get phoneCounterText =>
      (phoneLength.value == 0 || isPhoneValid.value) ? "" : null;
  bool get isNameValid => firstNameController.text.trim().isNotEmpty;
  bool get isSubmitEnabled => isNameValid && isPhoneValid.value;

  Future<void> startPhoneVerification() async {
    if (!isSubmitEnabled) {
      hasInteractedWithName.value = true;
      update();
      return;
    }

    isLoading.value = true;
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: completePhoneNumber.value,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification on Android
          if (Get.isRegistered<OtpCtrl>()) {
            Get.find<OtpCtrl>().completeWithCredential(credential);
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          isLoading.value = false;
          Get.snackbar("Auth Error", e.message ?? "Verification Failed");
        },
        codeSent: (String verId, int? resendToken) {
          _verificationId = verId;
          isLoading.value = false;
          Get.toNamed(Routes.otpPage);
        },
        codeAutoRetrievalTimeout: (String verId) {
          _verificationId = verId;
        },
      );
    } catch (e) {
      isLoading.value = false;
      Get.snackbar("Error", "Failed to send SMS code");
    }
  }

  // Helper method for the final Backend API call
  Future<void> callBackendApi(String firebaseUid) async {
    String profileImageData = "";
    if (selectedImagePath.value.isNotEmpty) {
      profileImageData = base64Encode(
        await File(selectedImagePath.value).readAsBytes(),
      );
    } else if (socialImageUrl.value.isNotEmpty) {
      profileImageData = socialImageUrl.value;
    } else {
      ByteData bytes = await rootBundle.load(
        'assets/images/${selectedDefaultImage.value}',
      );
      profileImageData = base64Encode(bytes.buffer.asUint8List());
    }

    final dio = Dio(BaseOptions(baseUrl: 'http://10.0.2.2:3000'));
    await dio.post(
      '/auth/register-or-link',
      data: {
        'firstName': firstNameController.text.trim(),
        'lastName': lastNameController.text.trim(),
        'email': data?['email'],
        'phoneNumber': completePhoneNumber.value,
        'profileImage': profileImageData,
        'gender': selectedGender.value,
        'firebaseUid': firebaseUid,
      },
    );
  }

  @override
  void onClose() {
    firstNameController.dispose();
    lastNameController.dispose();
    phoneController.dispose();
    nameFocusNode.dispose();
    super.onClose();
  }
}

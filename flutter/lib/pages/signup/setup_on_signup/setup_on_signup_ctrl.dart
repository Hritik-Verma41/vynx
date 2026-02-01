import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vynx/routes/app_routes.dart';
import 'package:vynx/pages/signup/otp/otp_ctrl.dart';

class SetupOnSignupCtrl extends GetxController {
  final data = Get.arguments;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final phoneController = TextEditingController();
  final nameFocusNode = FocusNode();

  var isPageReady = false.obs; // Used only for smooth image decoding
  var isLoading = false.obs;
  var selectedImagePath = "".obs;
  var socialImageUrl = "".obs;
  var selectedGender = "male".obs;
  var selectedDefaultImage = "".obs;

  var isPhoneValid = false.obs;
  var completePhoneNumber = "".obs;
  var phoneLength = 0.obs;
  var hasInteractedWithName = false.obs;

  final ImagePicker _picker = ImagePicker();
  String _verificationId = "";

  String get verificationIdValue => _verificationId;

  @override
  void onInit() {
    firstNameController.text = data?['firstName'] ?? "";
    lastNameController.text = data?['lastName'] ?? "";

    // We keep a small delay for images only to ensure the transition is smooth
    Future.delayed(const Duration(milliseconds: 300), () {
      isPageReady.value = true;
      _initializeImage();
    });
    super.onInit();
  }

  void _initializeImage() {
    String? incomingImage = data?['profileImage'] ?? data?['photoUrl'];
    if (incomingImage != null && incomingImage.startsWith('http')) {
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
        imageQuality: 60,
        maxWidth: 600,
      );
      if (image != null) {
        selectedImagePath.value = image.path;
        socialImageUrl.value = "";
        selectedDefaultImage.value = "";
      }
    } catch (e) {
      Get.snackbar("Error", "Could not access image.");
    }
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
          if (Get.isRegistered<OtpCtrl>()) {
            Get.find<OtpCtrl>().completeWithCredential(credential);
          }
        },
        verificationFailed: (e) {
          isLoading.value = false;
          Get.snackbar("Auth Error", e.message ?? "Verification Failed");
        },
        codeSent: (String verId, int? resendToken) {
          _verificationId = verId;
          isLoading.value = false;
          Get.toNamed(Routes.otpPage);
        },
        codeAutoRetrievalTimeout: (verId) => _verificationId = verId,
      );
    } catch (e) {
      isLoading.value = false;
      Get.snackbar("Error", "Check your connection and try again.");
    }
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

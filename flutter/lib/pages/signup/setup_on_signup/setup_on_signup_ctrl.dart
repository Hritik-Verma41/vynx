import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:vynx/routes/app_routes.dart';
import 'package:vynx/pages/signup/otp/otp_ctrl.dart';

class SetupOnSignupCtrl extends GetxController {
  final data = Get.arguments;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final RegExp _nameRegExp = RegExp(r"^[a-zA-Z\s]{2,50}$");
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final phoneController = TextEditingController();
  final nameFocusNode = FocusNode();

  var completePhoneNumber = "".obs;
  var firstNameStr = "".obs;
  var hasInteractedWithName = false.obs;
  var hasInteractedWithPhone = false.obs;
  var isLoading = false.obs;
  var isPageReady = false.obs;
  var isPhoneEmpty = true.obs;
  var isPhoneValid = false.obs;
  var phoneLength = 0.obs;
  var selectedDefaultImage = "".obs;
  var selectedGender = "male".obs;
  var selectedImagePath = "".obs;
  var socialImageUrl = "".obs;

  final ImagePicker _picker = ImagePicker();
  String _verificationId = "";

  String get verificationIdValue => _verificationId;

  @override
  void onInit() {
    firstNameController.text = data?['firstName'] ?? "";
    lastNameController.text = data?['lastName'] ?? "";

    firstNameStr.value = firstNameController.text;

    if (firstNameController.text.isNotEmpty) {
      hasInteractedWithName.value = true;
    }

    firstNameController.addListener(() {
      firstNameStr.value = firstNameController.text;
      if (firstNameController.text.isNotEmpty) {
        hasInteractedWithName.value = true;
      }
      update();
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      isPageReady.value = true;
      _initializeImage();
    });
    super.onInit();
  }

  void onPhoneChanged(PhoneNumber phone) {
    if (phone.number.isNotEmpty) {
      hasInteractedWithPhone.value = true;
    }
    phoneLength.value = phone.number.length;
    completePhoneNumber.value = phone.completeNumber;
    try {
      isPhoneValid.value = phone.isValidNumber();
    } catch (_) {
      isPhoneValid.value = false;
    }

    if (phone.number.isEmpty) {
      isPhoneEmpty.value = true;
    } else {
      isPhoneEmpty.value = false;
    }
  }

  bool get isNameValid {
    final name = firstNameStr.value.trim();
    return name.isNotEmpty && _nameRegExp.hasMatch(name);
  }

  bool get isSubmitEnabled => isNameValid && isPhoneValid.value;
  String get nameErrorText {
    final name = firstNameStr.value.trim();
    if (name.isEmpty) return "First name is required";
    if (name.length < 2) return "Name is too short";
    if (!_nameRegExp.hasMatch(name)) {
      return "Numbers and special characters are not allowed";
    }
    return "";
  }

  bool get showNameError => hasInteractedWithName.value && !isNameValid;
  bool get showPhoneError => hasInteractedWithPhone.value && isPhoneEmpty.value;

  String? get phoneCounterText =>
      (phoneLength.value == 0 || isPhoneValid.value) ? "" : null;

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

  Future<void> startPhoneVerification() async {
    if (!isSubmitEnabled) return;

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

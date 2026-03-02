import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vynx/config/api_urls.dart';
import 'package:vynx/controllers/user_controller.dart';
import 'package:vynx/routes/app_routes.dart';
import 'package:vynx/services/api_service.dart';
import 'package:vynx/services/auth_service.dart';
import 'package:vynx/services/cloudinary_service.dart';

class AccountInfoController extends GetxController {
  final UserController userCtrl = Get.put(UserController());
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthService _authService = Get.find<AuthService>();
  final _cloudinary = Get.find<CloudinaryService>();
  final Dio _dio = Get.find<ApiService>().dio;

  var selectedGender = "male".obs;
  var selectedDefaultImage = "".obs;
  var selectedImagePath = "".obs;
  var selectedStatus = "Available".obs;
  var isCustomStatus = false.obs;
  var isLoading = false.obs;

  var hasInteractedWithName = false.obs;
  var hasInteractedWithPhone = false.obs;
  var hasInteractedWithStatus = false.obs;

  var showNameError = false.obs;
  var showPhoneError = false.obs;
  var showStatusError = false.obs;

  var isSubmitEnabled = false.obs;

  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController phoneController;
  late TextEditingController customStatusController;

  String initialPhone = "";
  String verificationId = "";

  final List<String> statusOptions = [
    "Available",
    "Busy",
    "At Work",
    "In a Meeting",
    "Sleeping",
    "Urgent calls only",
    "Feeling Happy",
    "Coding...",
    "Traveling",
    "Custom...",
  ];

  @override
  void onInit() {
    super.onInit();
    final u = userCtrl.user.value;

    firstNameController = TextEditingController(text: u?.firstName ?? "");
    lastNameController = TextEditingController(text: u?.lastName ?? "");
    customStatusController = TextEditingController();

    initialPhone = u?.phoneNumber ?? "";
    String digitsOnly = initialPhone.replaceAll(RegExp(r'\D'), '');
    phoneController = TextEditingController(
      text: digitsOnly.length >= 10
          ? digitsOnly.substring(digitsOnly.length - 10)
          : digitsOnly,
    );

    selectedGender.value = u?.gender ?? 'male';
    _initStatus(u?.status);
    _initImage(u?.profileImage);

    validateForm();
  }

  void _initStatus(String? status) {
    String initialStatus = status ?? 'Available';
    if (statusOptions.contains(initialStatus) && initialStatus != "Custom...") {
      selectedStatus.value = initialStatus;
      isCustomStatus.value = false;
    } else {
      selectedStatus.value = "Custom...";
      isCustomStatus.value = true;
      customStatusController.text = initialStatus;
    }
  }

  void _initImage(String? pImg) {
    if (pImg != null && pImg.isNotEmpty && !pImg.startsWith('http')) {
      selectedDefaultImage.value = pImg;
    } else if (pImg == null || pImg.isEmpty) {
      setRandomDefaultImage();
    }
  }

  void setStatus(String? val) {
    if (val != null) {
      hasInteractedWithStatus.value = true;
      selectedStatus.value = val;
      isCustomStatus.value = (val == "Custom...");
      validateForm();
    }
  }

  void validateForm() {
    final name = firstNameController.text.trim();
    final phone = phoneController.text.trim();
    final customStatusText = customStatusController.text.trim();

    showNameError.value = hasInteractedWithName.value && name.isEmpty;
    showPhoneError.value = hasInteractedWithPhone.value && phone.isEmpty;

    bool statusIsInvalid = isCustomStatus.value && customStatusText.isEmpty;
    showStatusError.value = hasInteractedWithStatus.value && statusIsInvalid;

    bool statusValid = !isCustomStatus.value || customStatusText.isNotEmpty;
    isSubmitEnabled.value =
        name.isNotEmpty && phone.length >= 10 && statusValid;
  }

  Future<void> saveChanges() async {
    if (!isSubmitEnabled.value) return;

    String currentPhone = phoneController.text.trim();

    bool isPhoneChanged = !initialPhone.endsWith(currentPhone);

    if (isPhoneChanged) {
      await _verifyNewPhone("+91$currentPhone");
    } else {
      await _performDirectUpdate();
    }
  }

  Future<void> _verifyNewPhone(String fullPhone) async {
    isLoading.value = true;
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: fullPhone,
        verificationCompleted: (_) {},
        verificationFailed: (e) {
          isLoading.value = false;
          Get.snackbar("Error", e.message ?? "Verification failed");
        },
        codeSent: (verId, _) {
          verificationId = verId;
          isLoading.value = false;
          Get.toNamed(
            Routes.otpPage,
            arguments: {"isUpdate": true, "payload": _getUpdateData()},
          );
        },
        codeAutoRetrievalTimeout: (verId) => verificationId = verId,
      );
    } catch (e) {
      isLoading.value = false;
      Get.snackbar("Error", "Something went wrong");
    }
  }

  Future<void> _performDirectUpdate() async {
    isLoading.value = true;
    try {
      final String? oldImageUrl = userCtrl.user.value?.profileImage;
      final payload = _getUpdateData();
      bool hasNewImageUploaded = false;

      if (payload['profileImage'] == "upload") {
        final cloudRes = await _cloudinary.uploadImage(
          filePath: selectedImagePath.value,
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
        Get.back();
        Get.snackbar(
          "Success",
          "Account updated successfully",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withValues(alpha: 0.8),
          colorText: Colors.white,
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  Map<String, dynamic> _getUpdateData() {
    String imgVal = "";

    if (selectedImagePath.value.isNotEmpty) {
      imgVal = "upload";
    } else if (selectedDefaultImage.value.isNotEmpty) {
      imgVal = selectedDefaultImage.value;
    } else {
      imgVal = userCtrl.user.value?.profileImage ?? "";
    }

    return {
      "firstName": firstNameController.text.trim(),
      "lastName": lastNameController.text.trim(),
      "phoneNumber": phoneController.text.trim(),
      "gender": selectedGender.value,
      "status": isCustomStatus.value
          ? customStatusController.text.trim()
          : selectedStatus.value,
      "profileImage": imgVal,
    };
  }

  void setGender(String val) {
    if (selectedGender.value == val) return;
    selectedGender.value = val;
    if (selectedImagePath.value.isEmpty) setRandomDefaultImage();
    validateForm();
  }

  void setRandomDefaultImage() {
    int randomNum = (DateTime.now().millisecondsSinceEpoch % 5) + 1;
    selectedDefaultImage.value =
        "default-profile-${selectedGender.value}-$randomNum.png";
    selectedImagePath.value = "";
  }

  void selectSpecificDefault(String imgName) {
    selectedDefaultImage.value = imgName;
    selectedImagePath.value = "";
    validateForm();
  }

  Future<void> pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(
      source: source,
      imageQuality: 50,
    );
    if (pickedFile != null) {
      selectedImagePath.value = pickedFile.path;
      selectedDefaultImage.value = "";
      validateForm();
    }
  }

  Future<void> startPhoneVerification() async {
    String fullPhone = "+91${phoneController.text.trim()}";

    isLoading.value = true;
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: fullPhone,
        verificationCompleted: (PhoneAuthCredential credential) {},
        verificationFailed: (FirebaseAuthException e) {
          isLoading.value = false;
          Get.snackbar("Verification Failed", e.message ?? "Error occurred");
        },
        codeSent: (String verId, int? resendToken) {
          verificationId = verId;
          isLoading.value = false;

          if (Get.currentRoute != Routes.otpPage) {
            Get.toNamed(
              Routes.otpPage,
              arguments: {"isUpdate": true, "payload": _getUpdateData()},
            );
          } else {
            Get.snackbar("OTP Sent", "A new code has been sent to $fullPhone");
          }
        },
        codeAutoRetrievalTimeout: (String verId) {
          verificationId = verId;
        },
      );
    } catch (e) {
      isLoading.value = false;
      Get.snackbar("Error", "Could not request OTP. Try again.");
    }
  }

  bool isProviderLinked(String provider) =>
      userCtrl.user.value?.providers.contains(provider) ?? false;

  Future<void> linkAccount(String provider) async {
    if (isProviderLinked(provider)) return;
    isLoading.value = true;
    try {
      UserCredential? credential;
      String? uid;

      if (provider == 'google') {
        credential = await _authService.signInWithGoogle();
        uid = credential?.user?.uid;
      } else if (provider == 'facebook') {
        credential = await _authService.signInWithFacebook();
        uid = credential?.user?.uid;
      }

      if (uid != null) {
        final response = await _dio.post(
          ApiUrls.linkProvider,
          data: {'provider': provider, 'uid': uid},
        );

        if (response.statusCode == 200) {
          await userCtrl.fetchProfile();
          Get.snackbar(
            "Success",
            "$provider account linked successfully",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.withValues(alpha: 0.8),
            colorText: Colors.white,
          );
        }
      }
    } catch (e) {
      debugPrint("Linking Error: $e");
      Get.snackbar("Error", "Failed to link $provider account.");
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    firstNameController.dispose();
    lastNameController.dispose();
    phoneController.dispose();
    customStatusController.dispose();
    super.onClose();
  }
}

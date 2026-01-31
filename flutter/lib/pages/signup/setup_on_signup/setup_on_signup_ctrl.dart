import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vynx/routes/app_routes.dart';

class SetupOnSignupCtrl extends GetxController {
  final data = Get.arguments;

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final phoneController = TextEditingController();
  final nameFocusNode = FocusNode();

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

  // LOGIC: Hide counter if empty OR if validation passes for the specific country
  String? get phoneCounterText {
    if (phoneLength.value == 0 || isPhoneValid.value) {
      return "";
    }
    return null; // Shows default "n/max" when invalid
  }

  bool get isNameValid => firstNameController.text.trim().isNotEmpty;
  bool get isSubmitEnabled => isNameValid && isPhoneValid.value;

  @override
  void onInit() {
    firstNameController.text = data?['firstName'] ?? "";
    lastNameController.text = data?['lastName'] ?? "";
    phoneController.text = data?['phoneNumber'] ?? "";

    firstNameController.addListener(() {
      if (firstNameController.text.isNotEmpty || hasInteractedWithName.value) {
        hasInteractedWithName.value = true;
      }
      update();
    });

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
    if (selectedDefaultImage.value.isNotEmpty) {
      return AssetImage('assets/images/${selectedDefaultImage.value}');
    }
    return const AssetImage('assets/images/default-profile-male-1.png');
  }

  Future<void> finalizeRegistration() async {
    if (!isSubmitEnabled) {
      hasInteractedWithName.value = true;
      update();
      return;
    }
    isLoading.value = true;
    try {
      String profileImageData = "";
      if (selectedImagePath.value.isNotEmpty) {
        profileImageData = base64Encode(
          await File(selectedImagePath.value).readAsBytes(),
        );
      } else if (socialImageUrl.value.isNotEmpty) {
        profileImageData = socialImageUrl.value;
      } else if (selectedDefaultImage.value.isNotEmpty) {
        ByteData bytes = await rootBundle.load(
          'assets/images/${selectedDefaultImage.value}',
        );
        profileImageData = base64Encode(bytes.buffer.asUint8List());
      }

      final dio = Dio(BaseOptions(baseUrl: 'http://YOUR_API_IP:3000'));
      final response = await dio.post(
        '/auth/register-or-link',
        data: {
          'firstName': firstNameController.text.trim(),
          'lastName': lastNameController.text.trim(),
          'email': data?['email'],
          'phoneNumber': completePhoneNumber.value,
          'profileImage': profileImageData,
          'password': data?['password'],
          'provider': data?['authProvider'],
          'gender': selectedGender.value,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        Get.offAllNamed(Routes.chat);
      }
    } catch (e) {
      Get.snackbar("Error", "Account creation failed");
    } finally {
      isLoading.value = false;
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

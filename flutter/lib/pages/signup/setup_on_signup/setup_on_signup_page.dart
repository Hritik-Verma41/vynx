import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:vynx/pages/signup/setup_on_signup/setup_on_signup_ctrl.dart';

class SetupOnSignupPage extends StatelessWidget {
  const SetupOnSignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SetupOnSignupCtrl());
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          _buildBackground(isDark),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30),
                  _buildHeader(isDark),
                  const SizedBox(height: 25),

                  Obx(
                    () => Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _genderBtn(controller, "Male", "male"),
                        const SizedBox(width: 15),
                        _genderBtn(controller, "Female", "female"),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),
                  _buildMainAvatar(controller, context, isDark),
                  const SizedBox(height: 20),
                  Center(
                    child: _subText("Or select a cartoon avatar:", isDark),
                  ),
                  const SizedBox(height: 12),
                  _buildAvatarList(controller),
                  const SizedBox(height: 30),

                  _buildTextField(
                    hint: "First Name",
                    icon: Icons.person,
                    isDark: isDark,
                    controller: controller.firstNameController,
                    focusNode: controller.nameFocusNode,
                  ),
                  Obx(
                    () => _buildWarning(
                      show:
                          controller.hasInteractedWithName.value &&
                          !controller.isNameValid,
                      text: "First name is required",
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    hint: "Last Name (Optional)",
                    icon: Icons.person_outline,
                    isDark: isDark,
                    controller: controller.lastNameController,
                  ),
                  const SizedBox(height: 15),

                  // Phone Field - Loader Removed, renders immediately
                  _buildPhoneInput(controller, isDark),

                  const SizedBox(height: 40),
                  Obx(
                    () => _buildSubmitBtn(
                      label: "Finish & Create Account",
                      onPressed: controller.isSubmitEnabled
                          ? () => controller.startPhoneVerification()
                          : null,
                    ),
                  ),

                  const SizedBox(height: 25),
                  Center(child: _footerText(isDark)),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          Obx(
            () => controller.isLoading.value
                ? _loadingOverlay()
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // --- Avatar Logic ---
  Widget _buildMainAvatar(
    SetupOnSignupCtrl ctrl,
    BuildContext context,
    bool isDark,
  ) {
    return Center(
      child: Obx(
        () => GestureDetector(
          onTap: () => _showPickerSheet(context, ctrl, isDark),
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.purple, width: 3),
                ),
                child: ClipOval(
                  child: !ctrl.isPageReady.value
                      ? const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : _imageDispatcher(ctrl),
                ),
              ),
              const CircleAvatar(
                backgroundColor: Colors.purple,
                radius: 16,
                child: Icon(Icons.camera_alt, size: 16, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imageDispatcher(SetupOnSignupCtrl ctrl) {
    if (ctrl.selectedImagePath.value.isNotEmpty) {
      return Image.file(File(ctrl.selectedImagePath.value), fit: BoxFit.cover);
    }
    if (ctrl.socialImageUrl.value.isNotEmpty) {
      return Image.network(
        ctrl.socialImageUrl.value,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) => progress == null
            ? child
            : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    final asset = ctrl.selectedDefaultImage.value.isEmpty
        ? "default-profile-male-1.png"
        : ctrl.selectedDefaultImage.value;
    return Image.asset(
      'assets/images/$asset',
      fit: BoxFit.cover,
      frameBuilder: (c, child, f, s) => f == null
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : child,
    );
  }

  Widget _buildAvatarList(SetupOnSignupCtrl ctrl) {
    return SizedBox(
      height: 65,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Obx(() {
            // The gender or selection might change, so we keep the logic inside Obx
            final imgName =
                "default-profile-${ctrl.selectedGender.value}-${index + 1}.png";
            final isSelected = ctrl.selectedDefaultImage.value == imgName;

            return GestureDetector(
              onTap: () => ctrl.selectSpecificDefault(imgName),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 65,
                height: 65,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.purple : Colors.white10,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: ClipOval(
                      child: !ctrl.isPageReady.value
                          ? const Padding(
                              padding: EdgeInsets.all(15.0),
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                              ),
                            )
                          : Image.asset(
                              'assets/images/$imgName',
                              fit: BoxFit.cover,
                              frameBuilder: (c, child, frame, wasSync) {
                                if (wasSync) return child;
                                return frame == null
                                    ? const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 1,
                                        ),
                                      )
                                    : child;
                              },
                            ),
                    ),
                  ),
                ),
              ),
            );
          });
        },
      ),
    );
  }

  // --- Phone Field renders immediately ---
  Widget _buildPhoneInput(SetupOnSignupCtrl ctrl, bool isDark) {
    return Obx(
      () => IntlPhoneField(
        controller: ctrl.phoneController,
        initialCountryCode: 'IN',
        dropdownTextStyle: TextStyle(
          color: isDark ? Colors.white : Colors.black,
        ),
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: 'Phone Number',
          counterText: ctrl.phoneCounterText,
          filled: true,
          fillColor: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (phone) {
          ctrl.phoneLength.value = phone.number.length;
          ctrl.completePhoneNumber.value = phone.completeNumber;
          try {
            ctrl.isPhoneValid.value = phone.isValidNumber();
          } catch (_) {
            ctrl.isPhoneValid.value = false;
          }
        },
      ),
    );
  }

  // --- Helpers ---
  Widget _buildBackground(bool isDark) => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: isDark
            ? [const Color(0xFF1A0B2E), const Color(0xFF09040F)]
            : [const Color(0xFFF3E5F5), Colors.white],
      ),
    ),
  );
  Widget _buildHeader(bool isDark) => Column(
    children: [
      Center(
        child: Text(
          "Complete Your Profile",
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
      ),
      const SizedBox(height: 5),
      Text(
        "Set up your identity",
        style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
      ),
    ],
  );
  Widget _genderBtn(SetupOnSignupCtrl ctrl, String label, String val) =>
      ElevatedButton(
        onPressed: () => ctrl.setGender(val),
        style: ElevatedButton.styleFrom(
          backgroundColor: ctrl.selectedGender.value == val
              ? Colors.purple
              : Colors.grey.withValues(alpha: 0.1),
          foregroundColor: ctrl.selectedGender.value == val
              ? Colors.white
              : Colors.grey,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(label),
      );
  Widget _buildTextField({
    required String hint,
    required IconData icon,
    required bool isDark,
    required TextEditingController controller,
    FocusNode? focusNode,
  }) => TextField(
    controller: controller,
    focusNode: focusNode,
    style: TextStyle(color: isDark ? Colors.white : Colors.black),
    decoration: InputDecoration(
      prefixIcon: Icon(icon, color: Colors.purple),
      hintText: hint,
      filled: true,
      fillColor: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.black.withValues(alpha: 0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
    ),
  );
  Widget _buildSubmitBtn({
    required String label,
    required VoidCallback? onPressed,
  }) => Container(
    width: double.infinity,
    height: 55,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(15),
      gradient: onPressed == null
          ? null
          : const LinearGradient(
              colors: [Color(0xFF8E24AA), Color(0xFF4A148C)],
            ),
      color: onPressed == null ? Colors.grey.withValues(alpha: 0.3) : null,
    ),
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
  Widget _buildWarning({required bool show, required String text}) => show
      ? Padding(
          padding: const EdgeInsets.only(left: 10, top: 5),
          child: Text(
            text,
            style: const TextStyle(color: Colors.redAccent, fontSize: 12),
          ),
        )
      : const SizedBox.shrink();
  Widget _subText(String t, bool dark) => Text(
    t,
    style: TextStyle(
      color: dark ? Colors.white54 : Colors.black54,
      fontSize: 12,
    ),
  );
  Widget _footerText(bool dark) => Text(
    "Developed by Hritik Verma",
    style: TextStyle(
      color: dark ? Colors.white24 : Colors.black26,
      fontSize: 11,
    ),
  );
  Widget _loadingOverlay() => Container(
    color: Colors.black54,
    child: const Center(child: CircularProgressIndicator(color: Colors.purple)),
  );
  void _showPickerSheet(
    BuildContext context,
    SetupOnSignupCtrl ctrl,
    bool dark,
  ) => Get.bottomSheet(
    Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1A0B2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library, color: Colors.purple),
            title: const Text("Gallery"),
            onTap: () {
              Get.back();
              ctrl.pickImage(ImageSource.gallery);
            },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt, color: Colors.purple),
            title: const Text("Camera"),
            onTap: () {
              Get.back();
              ctrl.pickImage(ImageSource.camera);
            },
          ),
        ],
      ),
    ),
  );
}

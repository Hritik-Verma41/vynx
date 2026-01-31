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
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 30),
                            _buildHeader(isDark),
                            const SizedBox(height: 20),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildGenderBtn(controller, "Male", "male"),
                                const SizedBox(width: 15),
                                _buildGenderBtn(controller, "Female", "female"),
                              ],
                            ),
                            const SizedBox(height: 20),

                            _buildProfileAvatar(controller, context, isDark),
                            const SizedBox(height: 15),

                            Center(
                              child: Text(
                                "Or select a cartoon avatar:",
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white60
                                      : Colors.black54,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),

                            _buildAvatarList(controller),
                            const SizedBox(height: 20),

                            _buildField(
                              hint: "First Name",
                              icon: Icons.person,
                              isDark: isDark,
                              controller: controller.firstNameController,
                              focusNode: controller.nameFocusNode,
                            ),

                            GetBuilder<SetupOnSignupCtrl>(
                              builder: (ctrl) => _buildNameWarning(
                                show:
                                    ctrl.hasInteractedWithName.value &&
                                    !ctrl.isNameValid,
                                message: "First name is required",
                              ),
                            ),

                            const SizedBox(height: 12),

                            _buildField(
                              hint: "Last Name (Optional)",
                              icon: Icons.person_outline,
                              isDark: isDark,
                              controller: controller.lastNameController,
                            ),

                            const SizedBox(height: 12),

                            // DYNAMIC PHONE FIELD
                            Obx(
                              () => IntlPhoneField(
                                controller: controller.phoneController,
                                initialCountryCode: 'IN',
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                dropdownTextStyle: TextStyle(
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black,
                                  fontSize: 14,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Phone Number',
                                  counterText: controller
                                      .phoneCounterText, // Reacts to validity
                                  hintStyle: TextStyle(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.3)
                                        : Colors.black.withValues(alpha: 0.3),
                                  ),
                                  filled: true,
                                  fillColor: isDark
                                      ? Colors.white.withValues(alpha: 0.05)
                                      : Colors.black.withValues(alpha: 0.05),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  errorStyle: const TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 12,
                                  ),
                                ),
                                onChanged: (phone) {
                                  controller.phoneLength.value =
                                      phone.number.length;
                                  controller.completePhoneNumber.value =
                                      phone.completeNumber;
                                  try {
                                    // This library check handles various country lengths automatically
                                    controller.isPhoneValid.value = phone
                                        .isValidNumber();
                                  } catch (e) {
                                    controller.isPhoneValid.value = false;
                                  }
                                  controller.update();
                                },
                              ),
                            ),

                            const Spacer(),
                            const SizedBox(height: 20),

                            GetBuilder<SetupOnSignupCtrl>(
                              builder: (ctrl) {
                                return _buildActionButton(
                                  label: "Finish & Create Account",
                                  onPressed: ctrl.isSubmitEnabled
                                      ? () => ctrl.startPhoneVerification()
                                      : null,
                                );
                              },
                            ),

                            const SizedBox(height: 20),
                            Center(child: _buildFooter(isDark)),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Obx(
            () => controller.isLoading.value
                ? _buildLoadingOverlay()
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // --- Helpers ---

  Widget _buildBackground(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1A0B2E), const Color(0xFF09040F)]
              : [const Color(0xFFF3E5F5), Colors.white],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Column(
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
        const SizedBox(height: 8),
        Center(
          child: Text(
            "Choose your look and contact info.",
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileAvatar(
    SetupOnSignupCtrl controller,
    BuildContext context,
    bool isDark,
  ) {
    return Center(
      child: Obx(
        () => GestureDetector(
          onTap: () => _showImageSourceSheet(context, controller, isDark),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.purple, width: 3),
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.purple.withValues(alpha: 0.1),
                  backgroundImage: controller.getProfileImage(),
                ),
              ),
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.purple,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add_a_photo,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarList(SetupOnSignupCtrl controller) {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Obx(() {
            final img =
                "default-profile-${controller.selectedGender.value}-${index + 1}.png";
            final isSelected = controller.selectedDefaultImage.value == img;
            return GestureDetector(
              onTap: () => controller.selectSpecificDefault(img),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.purple : Colors.transparent,
                    width: 2.5,
                  ),
                ),
                child: CircleAvatar(
                  radius: 24,
                  backgroundImage: AssetImage('assets/images/$img'),
                ),
              ),
            );
          });
        },
      ),
    );
  }

  Widget _buildNameWarning({required bool show, required String message}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: show ? 20 : 0,
      padding: const EdgeInsets.only(left: 12, top: 4),
      child: show
          ? Text(
              message,
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildGenderBtn(
    SetupOnSignupCtrl controller,
    String label,
    String val,
  ) {
    return Obx(() {
      bool isSelected = controller.selectedGender.value == val;
      return ElevatedButton(
        onPressed: () => controller.setGender(val),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected
              ? Colors.purple
              : Colors.grey.withValues(alpha: 0.1),
          foregroundColor: isSelected ? Colors.white : Colors.grey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
          elevation: 0,
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      );
    });
  }

  Widget _buildField({
    required String hint,
    required IconData icon,
    required bool isDark,
    required TextEditingController controller,
    FocusNode? focusNode,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.purple, size: 20),
        hintText: hint,
        hintStyle: TextStyle(
          color: isDark
              ? Colors.white.withValues(alpha: 0.3)
              : Colors.black.withValues(alpha: 0.3),
        ),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required VoidCallback? onPressed,
  }) {
    return Container(
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(bool isDark) {
    return Text(
      "Developed by Hritik Verma",
      style: TextStyle(
        color: isDark
            ? Colors.white.withValues(alpha: 0.3)
            : Colors.black.withValues(alpha: 0.3),
        fontSize: 11,
        letterSpacing: 1.1,
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.6),
      child: const Center(
        child: CircularProgressIndicator(color: Colors.purple),
      ),
    );
  }

  void _showImageSourceSheet(
    BuildContext context,
    SetupOnSignupCtrl controller,
    bool isDark,
  ) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A0B2E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.purple),
              title: const Text("Gallery"),
              onTap: () {
                Get.back();
                controller.pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.purple),
              title: const Text("Camera"),
              onTap: () {
                Get.back();
                controller.pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }
}

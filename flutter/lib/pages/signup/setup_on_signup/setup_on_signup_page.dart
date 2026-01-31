import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vynx/pages/signup/setup_on_signup/setup_on_signup_ctrl.dart';

class SetupOnSignupPage extends StatelessWidget {
  const SetupOnSignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SetupOnSignupCtrl());
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xFF1A0B2E), const Color(0xFF09040F)]
                    : [const Color(0xFFF3E5F5), Colors.white],
              ),
            ),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 20,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Complete Your Profile",
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Choose your look to get started.",
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 30),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildGenderBtn(controller, "Male", "male"),
                                const SizedBox(width: 15),
                                _buildGenderBtn(controller, "Female", "female"),
                              ],
                            ),
                            const SizedBox(height: 30),

                            Obx(
                              () => GestureDetector(
                                onTap: () => _showImageSourceSheet(
                                  context,
                                  controller,
                                  isDark,
                                ),
                                child: Stack(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.purple,
                                          width: 3,
                                        ),
                                      ),
                                      child: CircleAvatar(
                                        radius: 65,
                                        backgroundColor: Colors.purple
                                            .withValues(alpha: 0.1),
                                        backgroundImage: controller
                                            .getProfileImage(),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 5,
                                      right: 5,
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: const BoxDecoration(
                                          color: Colors.purple,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.add_a_photo,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 25),

                            Text(
                              "Or choose a cartoon avatar:",
                              style: TextStyle(
                                color: isDark ? Colors.white60 : Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 70,
                              child: Obx(() {
                                final currentGender =
                                    controller.selectedGender.value;
                                return ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  shrinkWrap: true,
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: 5,
                                  itemBuilder: (context, index) {
                                    String img =
                                        "default-profile-$currentGender-${index + 1}.png";
                                    return GestureDetector(
                                      onTap: () =>
                                          controller.selectSpecificDefault(img),
                                      child: Obx(() {
                                        bool isSelected =
                                            controller
                                                    .selectedDefaultImage
                                                    .value ==
                                                img &&
                                            controller
                                                .selectedImagePath
                                                .isEmpty &&
                                            controller.socialImageUrl.isEmpty;

                                        return Container(
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isSelected
                                                  ? Colors.purple
                                                  : Colors.transparent,
                                              width: 2,
                                            ),
                                          ),
                                          child: CircleAvatar(
                                            radius: 28,
                                            backgroundImage: AssetImage(
                                              'assets/images/$img',
                                            ),
                                          ),
                                        );
                                      }),
                                    );
                                  },
                                );
                              }),
                            ),

                            const SizedBox(height: 40),

                            _buildField(
                              hint: "First Name",
                              icon: Icons.person,
                              isDark: isDark,
                              controller: controller.firstNameController,
                            ),
                            const SizedBox(height: 15),
                            _buildField(
                              hint: "Last Name (Optional)",
                              icon: Icons.person_outline,
                              isDark: isDark,
                              controller: controller.lastNameController,
                            ),
                            const SizedBox(height: 40),

                            _buildActionButton(
                              label: "Finish & Create Account",
                              onPressed: () =>
                                  controller.finalizeRegistration(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Text(
                    "Developed by Hritik Verma",
                    style: TextStyle(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.3)
                          : Colors.black.withValues(alpha: 0.3),
                      fontSize: 12,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Obx(
            () => controller.isLoading.value
                ? Container(
                    color: Colors.black.withValues(alpha: 0.6),
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.purple),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
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
          elevation: isSelected ? 4 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
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
  }) {
    return TextField(
      controller: controller,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.purple),
        hintText: hint,
        hintStyle: TextStyle(
          color: isDark
              ? Colors.white.withValues(alpha: 0.38)
              : Colors.black.withValues(alpha: 0.38),
        ),
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
  }

  Widget _buildActionButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: const LinearGradient(
          colors: [Color(0xFF8E24AA), Color(0xFF4A148C)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
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

  void _showImageSourceSheet(
    BuildContext context,
    SetupOnSignupCtrl controller,
    bool isDark,
  ) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A0B2E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Wrap(
          children: [
            const Center(
              child: SizedBox(
                width: 40,
                child: Divider(thickness: 4, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.purple),
              title: Text(
                "Gallery",
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
              ),
              onTap: () {
                Get.back();
                controller.pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.purple),
              title: Text(
                "Camera",
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
              ),
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

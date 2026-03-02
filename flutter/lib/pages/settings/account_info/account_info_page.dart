import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:vynx/pages/settings/account_info/account_info_controller.dart';

class AccountInfoPage extends StatelessWidget {
  const AccountInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(AccountInfoController());
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color fieldBg = isDark
        ? const Color(0xFF25163D)
        : const Color(0xFFF5F5F5);
    final Color dropdownBg = isDark ? const Color(0xFF1A0B2E) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color subTextColor = isDark
        ? const Color(0xFF9E9E9E)
        : const Color(0xFF616161);

    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text(
          "Account Info",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: textColor,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
        ),
      ),
      body: Stack(
        children: [
          _buildBackground(isDark),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  _buildSubHeader("Update your identity", isDark),
                  const SizedBox(height: 25),
                  Obx(
                    () => Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 10,
                        children: [
                          _genderBtn(ctrl, 'Male', 'male', isDark),
                          _genderBtn(ctrl, 'Female', 'female', isDark),
                          _genderBtn(ctrl, 'Other', 'other', isDark),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  _buildMainAvatar(ctrl, context, isDark),
                  const SizedBox(height: 20),
                  Center(
                    child: _subText(
                      "Or select a cartoon avatar:",
                      subTextColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildAvatarList(ctrl),
                  const SizedBox(height: 30),

                  _buildTextField(
                    hint: "First Name",
                    icon: Icons.person,
                    isDark: isDark,
                    bgColor: fieldBg,
                    textColor: textColor,
                    controller: ctrl.firstNameController,
                    onChanged: (val) {
                      ctrl.hasInteractedWithName.value = true;
                      ctrl.validateForm();
                    },
                  ),
                  Obx(
                    () => _buildWarning(
                      show: ctrl.showNameError.value,
                      text: "First name is required",
                    ),
                  ),

                  const SizedBox(height: 12),
                  _buildTextField(
                    hint: "Last Name (Optional)",
                    icon: Icons.person_outline,
                    isDark: isDark,
                    bgColor: fieldBg,
                    textColor: textColor,
                    controller: ctrl.lastNameController,
                  ),
                  const SizedBox(height: 15),

                  _buildPhoneInput(ctrl, isDark, fieldBg, textColor),
                  Obx(
                    () => _buildWarning(
                      show: ctrl.showPhoneError.value,
                      text: "Phone number is required",
                    ),
                  ),

                  const SizedBox(height: 15),

                  _subText("Status Message", subTextColor),
                  const SizedBox(height: 8),
                  Obx(
                    () => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          decoration: BoxDecoration(
                            color: fieldBg,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: ctrl.selectedStatus.value,
                              isExpanded: true,
                              borderRadius: BorderRadius.circular(20),
                              dropdownColor: dropdownBg,
                              icon: const Icon(
                                Icons.arrow_drop_down,
                                color: Colors.purple,
                              ),
                              style: TextStyle(color: textColor, fontSize: 14),
                              items: ctrl.statusOptions.map((String status) {
                                return DropdownMenuItem<String>(
                                  value: status,
                                  child: Text(status),
                                );
                              }).toList(),
                              onChanged: (val) => ctrl.setStatus(val),
                            ),
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: ctrl.isCustomStatus.value ? 75 : 0,
                          curve: Curves.easeInOut,
                          child: ctrl.isCustomStatus.value
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: _buildTextField(
                                    hint: "Enter your custom status",
                                    icon: Icons.edit_note,
                                    isDark: isDark,
                                    bgColor: fieldBg,
                                    textColor: textColor,
                                    controller: ctrl.customStatusController,
                                    onChanged: (val) {
                                      ctrl.hasInteractedWithStatus.value = true;
                                      ctrl.validateForm();
                                    },
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                        _buildWarning(
                          show: ctrl.showStatusError.value,
                          text: "Status message is required",
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),
                  Center(child: _subText("Linked Accounts", subTextColor)),
                  const SizedBox(height: 15),
                  Obx(
                    () => Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _socialIcon(
                          FontAwesomeIcons.google,
                          const Color(0xFFDB4437),
                          isDark,
                          isLinked: ctrl.isProviderLinked('google'),
                          onTap: () => ctrl.linkAccount('google'),
                        ),
                        const SizedBox(width: 25),
                        _socialIcon(
                          FontAwesomeIcons.facebook,
                          const Color(0xFF4267B2),
                          isDark,
                          isLinked: ctrl.isProviderLinked('facebook'),
                          onTap: () => ctrl.linkAccount('facebook'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  Obx(
                    () => _buildSubmitBtn(
                      label: "Save Changes",
                      onPressed: ctrl.isSubmitEnabled.value
                          ? () => ctrl.saveChanges()
                          : null,
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          Obx(
            () => ctrl.isLoading.value
                ? _loadingOverlay()
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildSubHeader(String sub, bool isDark) => Text(
    sub,
    style: TextStyle(
      color: isDark ? const Color(0xFFBDBDBD) : const Color(0xFF757575),
      fontSize: 14,
    ),
  );

  Widget _imageDispatcher(AccountInfoController ctrl) {
    if (ctrl.selectedImagePath.value.isNotEmpty) {
      return Image.file(
        File(ctrl.selectedImagePath.value),
        fit: BoxFit.cover,
        key: ValueKey(ctrl.selectedImagePath.value),
      );
    }
    if (ctrl.selectedDefaultImage.value.isNotEmpty) {
      return Image.asset(
        'assets/images/${ctrl.selectedDefaultImage.value}',
        fit: BoxFit.cover,
        key: ValueKey(ctrl.selectedDefaultImage.value),
      );
    }
    final u = ctrl.userCtrl.user.value;
    if (u?.profileImage != null && u!.profileImage!.startsWith('http')) {
      return Image.network(u.profileImage!, fit: BoxFit.cover);
    }
    return Image.asset(
      'assets/images/default-profile-male-1.png',
      fit: BoxFit.cover,
    );
  }

  Widget _socialIcon(
    IconData icon,
    Color brandColor,
    bool isDark, {
    required bool isLinked,
    required VoidCallback onTap,
  }) => Stack(
    children: [
      InkWell(
        onTap: isLinked ? null : onTap,
        borderRadius: BorderRadius.circular(50),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? const Color(0xFF2D1B4D) : const Color(0xFFEEEEEE),
            border: Border.all(
              color: isLinked ? Colors.green : Colors.transparent,
              width: 2,
            ),
          ),
          child: FaIcon(
            icon,
            color: isLinked ? brandColor.withAlpha(128) : brandColor,
            size: 22,
          ),
        ),
      ),
      if (isLinked)
        const Positioned(
          right: 0,
          bottom: 0,
          child: CircleAvatar(
            radius: 8,
            backgroundColor: Colors.green,
            child: Icon(Icons.check, size: 10, color: Colors.white),
          ),
        ),
    ],
  );

  Widget _buildPhoneInput(
    AccountInfoController ctrl,
    bool isDark,
    Color fieldBg,
    Color textColor,
  ) => IntlPhoneField(
    controller: ctrl.phoneController,
    initialCountryCode: 'IN',
    invalidNumberMessage: 'Invalid Mobile Number',
    dropdownTextStyle: TextStyle(color: textColor),
    style: TextStyle(color: textColor, fontSize: 14),
    decoration: InputDecoration(
      hintText: 'Phone Number',
      counterText: '',
      filled: true,
      fillColor: fieldBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
    ),
    onChanged: (phone) {
      ctrl.hasInteractedWithPhone.value = true;
      ctrl.validateForm();
    },
  );

  Widget _buildAvatarList(AccountInfoController ctrl) => SizedBox(
    height: 65,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: 5,
      itemBuilder: (context, index) {
        return Obx(() {
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
                  color: isSelected ? Colors.purple : Colors.transparent,
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: Image.asset('assets/images/$imgName', fit: BoxFit.cover),
              ),
            ),
          );
        });
      },
    ),
  );

  Widget _buildMainAvatar(
    AccountInfoController ctrl,
    BuildContext context,
    bool isDark,
  ) => Center(
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
              child: ClipOval(child: _imageDispatcher(ctrl)),
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

  Widget _buildTextField({
    required String hint,
    required IconData icon,
    required bool isDark,
    required Color bgColor,
    required Color textColor,
    required TextEditingController controller,
    Function(String)? onChanged,
  }) => TextField(
    controller: controller,
    onChanged: onChanged,
    style: TextStyle(color: textColor),
    decoration: InputDecoration(
      prefixIcon: Icon(icon, color: Colors.purple),
      hintText: hint,
      filled: true,
      fillColor: bgColor,
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
      color: onPressed == null ? const Color(0xFF424242) : null,
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

  Widget _buildWarning({required bool show, required String text}) =>
      AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: show ? 25 : 0,
        child: show
            ? Padding(
                padding: const EdgeInsets.only(left: 10, top: 5),
                child: Text(
                  text,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                ),
              )
            : const SizedBox.shrink(),
      );

  Widget _buildBackground(bool isDark) => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: isDark
            ? [const Color(0xFF1A0B2E), const Color(0xFF09040F)]
            : [const Color(0xFFF3E5F5), Colors.white],
      ),
    ),
  );

  Widget _genderBtn(
    AccountInfoController ctrl,
    String label,
    String val,
    bool isDark,
  ) => ElevatedButton(
    onPressed: () => ctrl.setGender(val),
    style: ElevatedButton.styleFrom(
      backgroundColor: ctrl.selectedGender.value == val
          ? Colors.purple
          : (isDark ? const Color(0xFF2D1B4D) : const Color(0xFFEEEEEE)),
      foregroundColor: ctrl.selectedGender.value == val
          ? Colors.white
          : Colors.grey,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    child: Text(label),
  );

  Widget _subText(String t, Color color) =>
      Text(t, style: TextStyle(color: color, fontSize: 12));

  Widget _loadingOverlay() => Container(
    color: Colors.black54,
    child: const Center(child: CircularProgressIndicator(color: Colors.purple)),
  );

  void _showPickerSheet(
    BuildContext context,
    AccountInfoController ctrl,
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

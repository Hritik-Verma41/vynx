import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:vynx/pages/signup/signup_ctrl.dart';
import '../../routes/app_routes.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final SignupCtrl controller = Get.put(SignupCtrl());

  @override
  void initState() {
    super.initState();
    controller.nameController.addListener(() => setState(() {}));
    controller.emailController.addListener(() => setState(() {}));
    controller.passwordController.addListener(() => setState(() {}));
    controller.confirmPasswordController.addListener(() => setState(() {}));
  }

  // New Name Error Getter
  String? get _nameError {
    if (controller.hasInteractedWithName.value &&
        controller.nameController.text.trim().isEmpty) {
      return "Full name is required";
    }
    return null;
  }

  String? get _emailError {
    final text = controller.emailController.text;
    if (text.isEmpty) return null;
    if (!GetUtils.isEmail(text)) return "Enter a valid email address";
    return null;
  }

  String? get _passwordError {
    final text = controller.passwordController.text;
    if (text.isEmpty) return null;
    if (text.length < 8 || text.length > 15) return "8-15 characters required";
    if (!RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*?[!@#\$&*~]).*$',
    ).hasMatch(text)) {
      return "Need uppercase, lowercase & special char";
    }
    return null;
  }

  String? get _confirmPasswordError {
    final text = controller.confirmPasswordController.text;
    if (text.isEmpty) return null;
    if (text != controller.passwordController.text) {
      return "Passwords do not match";
    }
    return null;
  }

  bool get _isFormValid {
    return controller.nameController.text.trim().isNotEmpty &&
        GetUtils.isEmail(controller.emailController.text) &&
        _passwordError == null &&
        controller.passwordController.text.isNotEmpty &&
        controller.confirmPasswordController.text ==
            controller.passwordController.text;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Obx(
        () => Stack(
          children: [
            _buildBackground(isDark),
            SafeArea(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    children: [
                      const SizedBox(height: 60),
                      _buildLogo(isDark),
                      const SizedBox(height: 25),

                      // Full Name Field with Reactive Error
                      GetBuilder<SignupCtrl>(
                        builder: (ctrl) => _buildField(
                          hint: 'Full Name',
                          icon: Icons.person_outline,
                          isDark: isDark,
                          controller: ctrl.nameController,
                          errorText: _nameError,
                        ),
                      ),

                      const SizedBox(height: 10),
                      _buildField(
                        hint: 'Email',
                        icon: Icons.email_outlined,
                        isDark: isDark,
                        controller: controller.emailController,
                        errorText: _emailError,
                      ),
                      const SizedBox(height: 10),
                      _buildField(
                        hint: 'Password',
                        icon: Icons.lock_outline,
                        isDark: isDark,
                        isPass: true,
                        controller: controller.passwordController,
                        errorText: _passwordError,
                      ),
                      const SizedBox(height: 10),
                      _buildField(
                        hint: 'Confirm Password',
                        icon: Icons.lock_reset_outlined,
                        isDark: isDark,
                        isPass: true,
                        controller: controller.confirmPasswordController,
                        errorText: _confirmPasswordError,
                      ),

                      const SizedBox(height: 20),
                      _buildActionButton(
                        label: "Sign Up",
                        onPressed: _isFormValid
                            ? () => controller.signup()
                            : null,
                      ),

                      const SizedBox(height: 20),
                      _buildSocialDivider(isDark),
                      const SizedBox(height: 15),
                      _buildSocialRow(controller, isDark),

                      const SizedBox(height: 20),
                      _buildLoginRedirect(isDark),
                      const SizedBox(height: 40),
                      _buildFooter(isDark),
                    ],
                  ),
                ),
              ),
            ),
            if (controller.isLoading.value) _buildLoadingOverlay(),
          ],
        ),
      ),
    );
  }

  // --- UI Helpers ---

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

  Widget _buildLogo(bool isDark) {
    return Column(
      children: [
        Image.asset(
          isDark
              ? 'assets/splash/vynx-dark-mode-splash-icon.png'
              : 'assets/splash/vynx-light-mode-splash-icon.png',
          height: 60,
        ),
        const SizedBox(height: 15),
        Text(
          "Create Account",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          "Join the Vynx community today",
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildField({
    required String hint,
    required IconData icon,
    required bool isDark,
    required TextEditingController controller,
    String? errorText,
    bool isPass = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPass,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        prefixIcon: Icon(
          icon,
          color: isDark ? Colors.purple[200] : Colors.purple[700],
          size: 20,
        ),
        hintText: hint,
        errorText: errorText,
        errorStyle: const TextStyle(fontSize: 10, color: Colors.redAccent),
        hintStyle: TextStyle(
          color: isDark
              ? Colors.white.withValues(alpha: 0.38)
              : Colors.black.withValues(alpha: 0.38),
        ),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.05),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required VoidCallback? onPressed,
  }) {
    final bool isDisabled = onPressed == null;
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: isDisabled
              ? [Colors.grey.shade400, Colors.grey.shade500]
              : [const Color(0xFF8E24AA), const Color(0xFF4A148C)],
        ),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSocialDivider(bool isDark) {
    return Text(
      "Or sign up with",
      style: TextStyle(
        fontSize: 12,
        color: isDark
            ? Colors.white.withValues(alpha: 0.5)
            : Colors.black.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildSocialRow(SignupCtrl controller, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _socialIcon(
          FontAwesomeIcons.google,
          const Color(0xFFDB4437),
          isDark,
          onTap: () => controller.signupWithGoogle(),
        ),
        const SizedBox(width: 25),
        _socialIcon(
          FontAwesomeIcons.facebook,
          const Color(0xFF4267B2),
          isDark,
          onTap: () => controller.signupWithFacebook(),
        ),
      ],
    );
  }

  Widget _buildLoginRedirect(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Already have an account? ",
          style: TextStyle(
            fontSize: 13,
            color: isDark
                ? Colors.white.withValues(alpha: 0.7)
                : Colors.black.withValues(alpha: 0.54),
          ),
        ),
        GestureDetector(
          onTap: () => Get.offNamed(Routes.login),
          child: Text(
            "Login",
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.purple[200] : Colors.purple[700],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(bool isDark) {
    return Text(
      "Developed by Hritik Verma",
      style: TextStyle(
        color: isDark
            ? Colors.white.withValues(alpha: 0.24)
            : Colors.black.withValues(alpha: 0.26),
        fontSize: 10,
        letterSpacing: 1.1,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.45),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.purple),
        ),
      ),
    );
  }

  Widget _socialIcon(
    IconData icon,
    Color brandColor,
    bool isDark, {
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.02),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.12),
          ),
        ),
        child: FaIcon(icon, color: brandColor, size: 22),
      ),
    );
  }
}

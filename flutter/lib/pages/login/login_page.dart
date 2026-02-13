import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:vynx/pages/login/login_ctrl.dart';
import '../../routes/app_routes.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final LoginCtrl ctrl = Get.put(LoginCtrl());

  @override
  void initState() {
    super.initState();
    ctrl.emailController.addListener(() => setState(() {}));
    ctrl.passwordController.addListener(() => setState(() {}));
  }

  String? get _emailError {
    if (!ctrl.hasInteractedWithEmail.value) return null;
    final text = ctrl.emailController.text;
    if (text.isEmpty) return "Email is required";
    if (!GetUtils.isEmail(text)) return "Invalid email format";
    return null;
  }

  String? get _passwordError {
    if (!ctrl.hasInteractedWithPassword.value) return null;
    final text = ctrl.passwordController.text;
    if (text.isEmpty) return "Password is required";
    if (text.length < 8) return "Min. 8 characters required";
    return null;
  }

  bool get _isFormValid {
    return GetUtils.isEmail(ctrl.emailController.text) &&
        ctrl.passwordController.text.length >= 8;
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
              child: Center(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    children: [
                      _buildLogo(isDark),
                      const SizedBox(height: 40),
                      _buildField(
                        hint: 'Email',
                        icon: Icons.email_outlined,
                        isDark: isDark,
                        controller: ctrl.emailController,
                        errorText: _emailError,
                      ),
                      const SizedBox(height: 15),
                      _buildField(
                        hint: 'Password',
                        icon: Icons.lock_outline,
                        isDark: isDark,
                        isPass: true,
                        controller: ctrl.passwordController,
                        errorText: _passwordError,
                      ),
                      _buildForgotPassword(isDark),
                      const SizedBox(height: 25),

                      _buildActionButton(
                        label: "Login",
                        onPressed: _isFormValid ? () => ctrl.login() : null,
                      ),

                      _buildServerErrorMessage(),

                      const SizedBox(height: 30),
                      _buildSocialDivider(isDark),
                      const SizedBox(height: 20),
                      _buildSocialRow(isDark),
                      const SizedBox(height: 30),
                      _buildSignupRedirect(isDark),
                      const SizedBox(height: 40),
                      _buildFooter(isDark),
                    ],
                  ),
                ),
              ),
            ),
            if (ctrl.isLoading.value) _buildLoadingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildServerErrorMessage() {
    return Obx(() {
      if (ctrl.serverError.value.isEmpty) return const SizedBox(height: 20);
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Text(
          ctrl.serverError.value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.redAccent,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    });
  }

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
          height: 90,
        ),
        const SizedBox(height: 20),
        Text(
          "Welcome Back",
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
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
    required VoidCallback? onPressed,
  }) {
    final bool isDisabled = onPressed == null;
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: isDisabled
            ? null
            : const LinearGradient(
                colors: [Color(0xFF8E24AA), Color(0xFF4A148C)],
              ),
        color: isDisabled ? Colors.grey.withValues(alpha: 0.3) : null,
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

  Widget _buildSocialRow(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _socialIcon(
          FontAwesomeIcons.google,
          const Color(0xFFDB4437),
          isDark,
          onTap: () => ctrl.loginWithGoogle(),
        ),
        const SizedBox(width: 25),
        _socialIcon(
          FontAwesomeIcons.facebook,
          const Color(0xFF4267B2),
          isDark,
          onTap: () => ctrl.loginWithFacebook(),
        ),
      ],
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
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.02),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        child: FaIcon(icon, color: brandColor, size: 25),
      ),
    );
  }

  Widget _buildForgotPassword(bool isDark) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {},
        child: Text(
          'Forgot Password?',
          style: TextStyle(
            color: isDark ? Colors.purple[200] : Colors.purple[700],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialDivider(bool isDark) => Text(
    "Or continue with",
    style: TextStyle(
      color: isDark ? Colors.white54 : Colors.black54,
      fontSize: 12,
    ),
  );

  Widget _buildSignupRedirect(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
        ),
        GestureDetector(
          onTap: () => Get.offNamed(Routes.signup),
          child: Text(
            "Sign Up",
            style: TextStyle(
              color: isDark ? Colors.purple[200] : Colors.purple[700],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(bool isDark) => Text(
    "Developed by Hritik Verma",
    style: TextStyle(
      color: isDark
          ? Colors.white.withValues(alpha: 0.2)
          : Colors.black.withValues(alpha: 0.2),
      fontSize: 10,
      letterSpacing: 1.2,
    ),
  );

  Widget _buildLoadingOverlay() => Positioned.fill(
    child: Container(
      color: Colors.black.withValues(alpha: 0.45),
      child: const Center(
        child: CircularProgressIndicator(color: Colors.purple),
      ),
    ),
  );
}

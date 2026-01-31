import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:vynx/pages/login/login_ctrl.dart';
import '../../routes/app_routes.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final LoginCtrl ctrl = Get.put(LoginCtrl());
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Obx(
        () => Stack(
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
                    child: SingleChildScrollView(
                      child: Container(
                        constraints: BoxConstraints(
                          minHeight: MediaQuery.of(context).size.height - 100,
                        ),
                        alignment: Alignment.center,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 30),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 40),
                              Image.asset(
                                isDark
                                    ? 'assets/splash/vynx-dark-mode-splash-icon.png'
                                    : 'assets/splash/vynx-light-mode-splash-icon.png',
                                height: 120,
                              ),
                              const SizedBox(height: 40),
                              _buildTextField(
                                hint: 'Email',
                                icon: Icons.email_outlined,
                                isDark: isDark,
                                controller: ctrl.emailController,
                              ),
                              const SizedBox(height: 20),
                              _buildTextField(
                                hint: 'Password',
                                icon: Icons.lock_outline,
                                isDark: isDark,
                                isPassword: true,
                                controller: ctrl.passwordController,
                              ),
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {},
                                  child: Text(
                                    'Forgot Password?',
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.purple[200]
                                          : Colors.purple[700],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              _buildLoginButton(ctrl),
                              const SizedBox(height: 30),
                              const Text("Or continue with"),
                              const SizedBox(height: 20),
                              Row(
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
                              ),
                              const SizedBox(height: 30),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Don't have an account? ",
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black87,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => Get.offNamed(Routes.signup),
                                    child: Text(
                                      "Sign Up",
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.purple[200]
                                            : Colors.purple[700],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 40),
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
            if (ctrl.isLoading.value)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.5),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.purple),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginButton(LoginCtrl ctrl) {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: const LinearGradient(
          colors: [Color(0xFF8E24AA), Color(0xFF4A148C)],
        ),
      ),
      child: ElevatedButton(
        onPressed: () => ctrl.login(),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: const Text(
          'Login',
          style: TextStyle(
            fontSize: 18,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String hint,
    required IconData icon,
    required bool isDark,
    required TextEditingController controller,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        prefixIcon: Icon(
          icon,
          color: isDark ? Colors.purple[200] : Colors.purple[700],
        ),
        hintText: hint,
        hintStyle: TextStyle(
          color: isDark
              ? Colors.white.withValues(alpha: 0.5)
              : Colors.black.withValues(alpha: 0.5),
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
}

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import '../../routes/app_routes.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        width: double.infinity,
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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      isDark
                          ? 'assets/splash/vynx-dark-mode-splash-icon.png'
                          : 'assets/splash/vynx-light-mode-splash-icon.png',
                      height: 80,
                    ),
                    const SizedBox(height: 20),

                    Text(
                      "Create Account",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      "Join the Vynx community today",
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 30),

                    _buildField(
                      hint: 'Full Name',
                      icon: Icons.person_outline,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _buildField(
                      hint: 'Email',
                      icon: Icons.email_outlined,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _buildField(
                      hint: 'Password',
                      icon: Icons.lock_outline,
                      isDark: isDark,
                      isPass: true,
                    ),
                    const SizedBox(height: 12),

                    _buildField(
                      hint: 'Confirm Password',
                      icon: Icons.lock_reset_outlined,
                      isDark: isDark,
                      isPass: true,
                    ),

                    const SizedBox(height: 25),

                    _buildActionButton(
                      label: "Sign Up",
                      onPressed: () => Get.offAllNamed(Routes.chat),
                    ),

                    const SizedBox(height: 20),
                    const Text("Or sign up with"),
                    const SizedBox(height: 15),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _socialIcon(
                          FontAwesomeIcons.google,
                          const Color(0xFFDB4437),
                          isDark,
                        ),
                        const SizedBox(width: 25),
                        _socialIcon(
                          FontAwesomeIcons.facebook,
                          const Color(0xFF4267B2),
                          isDark,
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Already have an account? "),
                        GestureDetector(
                          onTap: () => Get.offNamed(Routes.login),
                          child: Text(
                            "Login",
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
                  ],
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required String hint,
    required IconData icon,
    required bool isDark,
    bool isPass = false,
  }) {
    return TextField(
      obscureText: isPass,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        prefixIcon: Icon(
          icon,
          color: isDark ? Colors.purple[200] : Colors.purple[700],
        ),
        hintText: hint,
        hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.05),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
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

  Widget _socialIcon(IconData icon, Color brandColor, bool isDark) {
    return InkWell(
      onTap: () {},
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

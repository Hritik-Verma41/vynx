import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vynx/pages/settings/security_settings/security_settings_controller.dart';

class SecuritySettingsPage extends StatelessWidget {
  const SecuritySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final securitySettingCtrl = Get.put(SecuritySettingsController());
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Security',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: isDark ? Colors.white : Colors.black,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF1A0B2E), const Color(0xFF09040F)]
                : [const Color(0xFFF3E5F5), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader("App Protection", isDark),
                const SizedBox(height: 12),
                _buildGlassContainer(
                  isDark,
                  child: Obx(
                    () => SwitchListTile(
                      secondary: Icon(
                        Icons.phonelink_lock_rounded,
                        color: isDark ? Colors.purple[200] : Colors.purple[700],
                      ),
                      title: const Text(
                        "Screen Loack",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        Platform.isAndroid
                            ? "Use your phone's PIN, pattern, or biometrics to unlock Vynx"
                            : "Use your phone's PIN or face ID to unlock Vynx",
                        style: TextStyle(fontSize: 12),
                      ),
                      value: securitySettingCtrl.isAppLockEnabled.value,
                      activeThumbColor: Colors.pinkAccent,
                      onChanged: (val) =>
                          securitySettingCtrl.toggleAppLock(val),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    "Note: When enabled, you will need to authenticate every time you open the app or return to it after a period of inactivity.",
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassContainer(bool isDark, {required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: child,
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: EdgeInsetsGeometry.only(left: 10),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.purple[200] : Colors.purple[700],
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

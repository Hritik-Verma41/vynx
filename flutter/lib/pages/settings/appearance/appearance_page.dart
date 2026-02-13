import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vynx/services/storage_service.dart';

class AppearancePage extends StatelessWidget {
  const AppearancePage({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = Get.find<StorageService>();
    final currentMode = storage.getThemeMode().obs;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Appearance",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : Colors.black,
      ),
      body: Container(
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
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader("Theme Mode", isDark),
                const SizedBox(height: 12),
                Container(
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
                  child: Column(
                    children: [
                      _buildThemeTile(
                        "System Default",
                        Icons.brightness_auto_outlined,
                        ThemeMode.system,
                        currentMode,
                        storage,
                        isDark,
                        showDivider: true,
                      ),
                      _buildThemeTile(
                        "Light Mode",
                        Icons.light_mode_outlined,
                        ThemeMode.light,
                        currentMode,
                        storage,
                        isDark,
                        showDivider: true,
                      ),
                      _buildThemeTile(
                        "Dark Mode",
                        Icons.dark_mode_outlined,
                        ThemeMode.dark,
                        currentMode,
                        storage,
                        isDark,
                        showDivider: false,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    "Switching to System Default will automatically adjust Vynx's appearance based on your device settings.",
                    style: TextStyle(
                      fontSize: 13,
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

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.purple[200] : Colors.purple[700],
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildThemeTile(
    String title,
    IconData icon,
    ThemeMode mode,
    Rx<ThemeMode> current,
    StorageService storage,
    bool isDark, {
    required bool showDivider,
  }) {
    return Obx(() {
      bool isSelected = current.value == mode;
      return Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 4,
            ),
            leading: Icon(
              icon,
              color: isSelected
                  ? (isDark ? Colors.purple[200] : Colors.purple[700])
                  : (isDark ? Colors.white70 : Colors.black87),
            ),
            title: Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            trailing: isSelected
                ? Icon(
                    Icons.check_circle,
                    color: isDark ? Colors.purple[200] : Colors.purple[700],
                  )
                : null,
            onTap: () {
              current.value = mode;
              Get.changeThemeMode(mode);
              storage.saveThemeMode(mode);
            },
          ),
          if (showDivider)
            Divider(
              indent: 60,
              endIndent: 20,
              height: 1,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.1),
            ),
        ],
      );
    });
  }
}

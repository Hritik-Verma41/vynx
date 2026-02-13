import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vynx/pages/settings/settings_page.dart';
import 'package:vynx/pages/vynx_hub/vynx_hub_contoller.dart';

class VynxHubPage extends StatelessWidget {
  const VynxHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(VynxHubController());
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF1A0B2E), const Color(0xFF09040F)]
                : [const Color(0xFFF3E5F5), Colors.white],
          ),
        ),
        child: Obx(
          () => IndexedStack(
            index: controller.currentIndex.value,
            children: [
              _buildPlaceholder("Chats", Icons.chat),
              _buildPlaceholder("Status", Icons.circle_outlined),
              _buildPlaceholder("Calls", Icons.call),
              const SettingsPage(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Obx(
        () => Theme(
          data: Theme.of(context).copyWith(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            canvasColor: isDark ? const Color(0xFF0F0816) : Colors.white,
          ),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.05),
                  width: 1,
                ),
              ),
            ),
            child: BottomNavigationBar(
              currentIndex: controller.currentIndex.value,
              onTap: (index) => controller.changeTab(index),
              type: BottomNavigationBarType.fixed,
              elevation: 0,
              backgroundColor: isDark ? const Color(0xFF0F0816) : Colors.white,
              selectedItemColor: isDark
                  ? Colors.purple[200]
                  : Colors.purple[700],
              unselectedItemColor: isDark
                  ? Colors.white.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.3),
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              unselectedLabelStyle: const TextStyle(fontSize: 12),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.chat_bubble_outline),
                  activeIcon: Icon(Icons.chat_bubble),
                  label: 'Chats',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.blur_circular_outlined),
                  activeIcon: Icon(Icons.blur_circular),
                  label: 'Status',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.phone_outlined),
                  activeIcon: Icon(Icons.phone),
                  label: 'Calls',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings_outlined),
                  activeIcon: Icon(Icons.settings),
                  label: 'Settings',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(String title, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.purple.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 18, color: Colors.grey)),
        ],
      ),
    );
  }
}

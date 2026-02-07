import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return CustomScrollView(
      slivers: [
        // Premium AppBar
        SliverAppBar(
          expandedHeight: 120,
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              "Settings",
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: false,
            titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
          ),
        ),

        // Settings Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _buildProfileCard(isDark),
                const SizedBox(height: 30),
                _buildSettingsGroup("Account", [
                  _settingsTile(Icons.person_outline, "Account Info", isDark),
                  _settingsTile(Icons.privacy_tip_outlined, "Privacy", isDark),
                  _settingsTile(Icons.security_outlined, "Security", isDark),
                ], isDark),
                const SizedBox(height: 20),
                _buildSettingsGroup("Preferences", [
                  _settingsTile(
                    Icons.notifications_none_outlined,
                    "Notifications",
                    isDark,
                  ),
                  _settingsTile(Icons.palette_outlined, "Appearance", isDark),
                  _settingsTile(
                    Icons.data_usage_outlined,
                    "Data Usage",
                    isDark,
                  ),
                ], isDark),
                const SizedBox(height: 40),
                _buildLogoutButton(isDark),
                const SizedBox(height: 100), // Space for BottomNav
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: Colors.purple.withValues(alpha: 0.2),
            child: const Icon(Icons.person, size: 40, color: Colors.purple),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Hritik Verma",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  "Available",
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.qr_code,
              color: isDark ? Colors.purple[200] : Colors.purple[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup(String title, List<Widget> tiles, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.purple[200] : Colors.purple[700],
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.03)
                : Colors.black.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(children: tiles),
        ),
      ],
    );
  }

  Widget _settingsTile(IconData icon, String title, bool isDark) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDark ? Colors.white70 : Colors.black87,
        size: 22,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
      onTap: () {},
    );
  }

  Widget _buildLogoutButton(bool isDark) {
    return TextButton.icon(
      onPressed: () {
        // Handle Logout Logic
      },
      icon: const Icon(Icons.logout, color: Colors.redAccent),
      label: const Text(
        "Logout",
        style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
      ),
    );
  }
}

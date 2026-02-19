import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vynx/pages/settings/privacy_settings/privacy_settings_controller.dart';

class PrivacySettingsPage extends StatelessWidget {
  const PrivacySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PrivacySettingsController());
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Privacy",
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
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF1A0B2E), const Color(0xFF09040F)]
                : [const Color(0xFFF3E5F5), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Obx(() {
            if (controller.isLoading.value ||
                controller.privacySettings.value == null) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.purple),
              );
            }

            final s = controller.privacySettings.value!;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader("Who can see my personal info", isDark),
                  const SizedBox(height: 12),
                  _buildGlassContainer(
                    isDark,
                    child: Column(
                      children: [
                        _buildTile(
                          'Last seen & online',
                          s.lastSeen,
                          Icons.visibility_outlined,
                          () => _buildLastSeenAndOnlineDialog(
                            context,
                            controller,
                          ),
                          isDark,
                          showDivider: true,
                        ),
                        _buildTile(
                          'Profile picture',
                          s.profilePicture,
                          Icons.account_circle_outlined,
                          () => _buildStandardDialog(
                            'Profile picture',
                            'profilePicture',
                            controller,
                          ),
                          isDark,
                          showDivider: true,
                        ),
                        _buildTile(
                          'Status',
                          s.status,
                          Icons.info_outline,
                          () => _buildStandardDialog(
                            'Status',
                            'status',
                            controller,
                          ),
                          isDark,
                          showDivider: false,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader("Messaging", isDark),
                  const SizedBox(height: 12),
                  _buildGlassContainer(
                    isDark,
                    child: SwitchListTile(
                      title: Text(
                        'Read receipts',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Text(
                        "If turned off, you won't send or receive receipts.",
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                      value: s.readReceipts,
                      activeThumbColor: isDark
                          ? Colors.purple[200]
                          : Colors.purple[700],
                      onChanged: (val) =>
                          controller.updatePrivacySettings('readReceipts', val),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      "Note: If you don't share your Last Seen and Online, you won't be able to see other people's Last Seen and Online.",
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
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

  Widget _buildTile(
    String title,
    String val,
    IconData icon,
    VoidCallback onTap,
    bool isDark, {
    required bool showDivider,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 4,
          ),
          leading: Icon(icon, color: isDark ? Colors.white70 : Colors.black87),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 15,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          subtitle: Text(
            val.replaceAll('_', ' ').capitalizeFirst!,
            style: TextStyle(
              color: isDark ? Colors.purple[200] : Colors.purple[700],
              fontWeight: FontWeight.w600,
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right,
            size: 20,
            color: Colors.grey,
          ),
          onTap: onTap,
        ),
        if (showDivider)
          Divider(
            indent: 60,
            endIndent: 20,
            height: 1,
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
          ),
      ],
    );
  }

  void _buildStandardDialog(
    String title,
    String key,
    PrivacySettingsController ctrl,
  ) {
    Get.dialog(
      SimpleDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        children: [
          Obx(() {
            final s = ctrl.privacySettings.value!;
            final String currentVal = s.toJson()[key] ?? 'everyone';

            return RadioGroup<String>(
              groupValue: currentVal,
              onChanged: (v) {
                if (v != null) ctrl.updatePrivacySettings(key, v);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: ['everyone', 'contacts', 'nobody']
                    .map(
                      (e) => RadioListTile<String>(
                        title: Text(e.capitalizeFirst!),
                        value: e,
                        activeColor: Colors.purple,
                      ),
                    )
                    .toList(),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _buildLastSeenAndOnlineDialog(
    BuildContext context,
    PrivacySettingsController ctrl,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Obx(() {
          final s = ctrl.privacySettings.value!;

          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Who can see my last seen",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 10),
                RadioGroup<String>(
                  groupValue: s.lastSeen,
                  onChanged: (v) => ctrl.updatePrivacySettings('lastSeen', v!),
                  child: Column(
                    children: ['everyone', 'contacts', 'nobody']
                        .map(
                          (e) => RadioListTile<String>(
                            title: Text(e.capitalizeFirst!),
                            value: e,
                            activeColor: Colors.purple,
                          ),
                        )
                        .toList(),
                  ),
                ),
                const Divider(height: 30),
                const Text(
                  "Who can see when I'm online",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 10),
                RadioGroup<String>(
                  groupValue: s.online,
                  onChanged: (v) => ctrl.updatePrivacySettings('online', v!),
                  child: Column(
                    children: ['everyone', 'same_as_last_seen']
                        .map(
                          (e) => RadioListTile<String>(
                            title: Text(
                              e == 'everyone'
                                  ? 'Everyone'
                                  : 'Same as last seen',
                            ),
                            value: e,
                            activeColor: Colors.purple,
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

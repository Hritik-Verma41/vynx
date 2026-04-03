import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vynx/pages/settings/notifications/notifications_settings_controller.dart';

class NotificationsSettingsPage extends StatelessWidget {
  const NotificationsSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<NotificationsSettingsController>();
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Notifications",
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
            final s = ctrl.settings.value;

            if (ctrl.isLoading.value && s == null) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.purple),
              );
            }

            if (s == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.notifications_off_outlined,
                        size: 48,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Couldn't load notification settings.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Check your connection and try again.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ctrl.fetchSettings(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text("Retry"),
                      ),
                    ],
                  ),
                ),
              );
            }

            final bool enabled = s.enabled;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader("General", isDark),
                  const SizedBox(height: 12),
                  _buildGlassContainer(
                    isDark,
                    child: SwitchListTile(
                      title: Text(
                        "Enable notifications",
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Text(
                        "Turn off to mute all alerts from Vynx.",
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                      value: enabled,
                      activeThumbColor: isDark
                          ? Colors.purple[200]
                          : Colors.purple[700],
                      onChanged: (v) {
                        ctrl.updateSetting('enabled', v);
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildSectionHeader("Messages", isDark),
                  const SizedBox(height: 12),
                  _buildGlassContainer(
                    isDark,
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: Text(
                            "Message preview",
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Text(
                            "Show sender and message content.",
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                          ),
                          value: s.messagePreview,
                          activeThumbColor: isDark
                              ? Colors.purple[200]
                              : Colors.purple[700],
                          onChanged: enabled
                              ? (v) {
                                  ctrl.updateSetting('messagePreview', v);
                                }
                              : null,
                        ),
                        Divider(
                          indent: 60,
                          endIndent: 20,
                          height: 1,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.05),
                        ),
                        SwitchListTile(
                          title: Text(
                            "Sound",
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Text(
                            "Play a sound for new messages.",
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                          ),
                          value: s.sound,
                          activeThumbColor: isDark
                              ? Colors.purple[200]
                              : Colors.purple[700],
                          onChanged: enabled
                              ? (v) {
                                  ctrl.updateSetting('sound', v);
                                }
                              : null,
                        ),
                        Divider(
                          indent: 60,
                          endIndent: 20,
                          height: 1,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.05),
                        ),
                        SwitchListTile(
                          title: Text(
                            "Vibrate",
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Text(
                            "Vibrate on new messages.",
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                          ),
                          value: s.vibrate,
                          activeThumbColor: isDark
                              ? Colors.purple[200]
                              : Colors.purple[700],
                          onChanged: enabled
                              ? (v) {
                                  ctrl.updateSetting('vibrate', v);
                                }
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildSectionHeader("Calls", isDark),
                  const SizedBox(height: 12),
                  _buildGlassContainer(
                    isDark,
                    child: SwitchListTile(
                      title: Text(
                        "Call notifications",
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Text(
                        "Show incoming call alerts.",
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                      value: s.calls,
                      activeThumbColor: isDark
                          ? Colors.purple[200]
                          : Colors.purple[700],
                      onChanged: enabled
                          ? (v) {
                              ctrl.updateSetting('calls', v);
                            }
                          : null,
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
}

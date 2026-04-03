import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vynx/pages/settings/data_usage/data_usage_settings_controller.dart';

class DataUsageSettingsPage extends StatelessWidget {
  const DataUsageSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<DataUsageSettingsController>();
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Data Usage",
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Obx(() {
              final saver = ctrl.dataSaver.value;
              final disableMobileHeavy = saver;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _section("Data Saver", isDark),
                  const SizedBox(height: 12),
                  _glass(
                    isDark,
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: _title("Data Saver", isDark),
                          subtitle: _sub(
                            "Reduce mobile data usage for media downloads.",
                            isDark,
                          ),
                          value: saver,
                          activeThumbColor: isDark
                              ? Colors.purple[200]
                              : Colors.purple[700],
                          onChanged: ctrl.setDataSaver,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  _section("Auto-Download (Mobile Data)", isDark),
                  const SizedBox(height: 12),
                  _glass(
                    isDark,
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: _title("Photos", isDark),
                          subtitle: _sub(
                            "Auto-download photos on mobile data.",
                            isDark,
                          ),
                          value: ctrl.mobilePhotos.value,
                          activeThumbColor: isDark
                              ? Colors.purple[200]
                              : Colors.purple[700],
                          onChanged: ctrl.setMobilePhotos,
                        ),
                        _divider(isDark),
                        SwitchListTile(
                          title: _title("Videos", isDark),
                          subtitle: _sub(
                            disableMobileHeavy
                                ? "Disabled by Data Saver."
                                : "Auto-download videos on mobile data.",
                            isDark,
                          ),
                          value: ctrl.mobileVideos.value,
                          activeThumbColor: isDark
                              ? Colors.purple[200]
                              : Colors.purple[700],
                          onChanged: disableMobileHeavy
                              ? null
                              : ctrl.setMobileVideos,
                        ),
                        _divider(isDark),
                        SwitchListTile(
                          title: _title("Audio", isDark),
                          subtitle: _sub(
                            disableMobileHeavy
                                ? "Disabled by Data Saver."
                                : "Auto-download audio on mobile data.",
                            isDark,
                          ),
                          value: ctrl.mobileAudio.value,
                          activeThumbColor: isDark
                              ? Colors.purple[200]
                              : Colors.purple[700],
                          onChanged: disableMobileHeavy
                              ? null
                              : ctrl.setMobileAudio,
                        ),
                        _divider(isDark),
                        SwitchListTile(
                          title: _title("Documents", isDark),
                          subtitle: _sub(
                            disableMobileHeavy
                                ? "Disabled by Data Saver."
                                : "Auto-download documents on mobile data.",
                            isDark,
                          ),
                          value: ctrl.mobileDocuments.value,
                          activeThumbColor: isDark
                              ? Colors.purple[200]
                              : Colors.purple[700],
                          onChanged: disableMobileHeavy
                              ? null
                              : ctrl.setMobileDocuments,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  _section("Auto-Download (Wi‑Fi)", isDark),
                  const SizedBox(height: 12),
                  _glass(
                    isDark,
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: _title("Photos", isDark),
                          subtitle: _sub(
                            "Auto-download photos on Wi‑Fi.",
                            isDark,
                          ),
                          value: ctrl.wifiPhotos.value,
                          activeThumbColor: isDark
                              ? Colors.purple[200]
                              : Colors.purple[700],
                          onChanged: ctrl.setWifiPhotos,
                        ),
                        _divider(isDark),
                        SwitchListTile(
                          title: _title("Videos", isDark),
                          subtitle: _sub(
                            "Auto-download videos on Wi‑Fi.",
                            isDark,
                          ),
                          value: ctrl.wifiVideos.value,
                          activeThumbColor: isDark
                              ? Colors.purple[200]
                              : Colors.purple[700],
                          onChanged: ctrl.setWifiVideos,
                        ),
                        _divider(isDark),
                        SwitchListTile(
                          title: _title("Audio", isDark),
                          subtitle: _sub(
                            "Auto-download audio on Wi‑Fi.",
                            isDark,
                          ),
                          value: ctrl.wifiAudio.value,
                          activeThumbColor: isDark
                              ? Colors.purple[200]
                              : Colors.purple[700],
                          onChanged: ctrl.setWifiAudio,
                        ),
                        _divider(isDark),
                        SwitchListTile(
                          title: _title("Documents", isDark),
                          subtitle: _sub(
                            "Auto-download documents on Wi‑Fi.",
                            isDark,
                          ),
                          value: ctrl.wifiDocuments.value,
                          activeThumbColor: isDark
                              ? Colors.purple[200]
                              : Colors.purple[700],
                          onChanged: ctrl.setWifiDocuments,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  _section("Auto-Download (Roaming)", isDark),
                  const SizedBox(height: 12),
                  _glass(
                    isDark,
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: _title("Photos", isDark),
                          subtitle: _sub("May incur roaming charges.", isDark),
                          value: ctrl.roamingPhotos.value,
                          activeThumbColor: isDark
                              ? Colors.purple[200]
                              : Colors.purple[700],
                          onChanged: ctrl.setRoamingPhotos,
                        ),
                        _divider(isDark),
                        SwitchListTile(
                          title: _title("Videos", isDark),
                          subtitle: _sub("May incur roaming charges.", isDark),
                          value: ctrl.roamingVideos.value,
                          activeThumbColor: isDark
                              ? Colors.purple[200]
                              : Colors.purple[700],
                          onChanged: ctrl.setRoamingVideos,
                        ),
                        _divider(isDark),
                        SwitchListTile(
                          title: _title("Audio", isDark),
                          subtitle: _sub("May incur roaming charges.", isDark),
                          value: ctrl.roamingAudio.value,
                          activeThumbColor: isDark
                              ? Colors.purple[200]
                              : Colors.purple[700],
                          onChanged: ctrl.setRoamingAudio,
                        ),
                        _divider(isDark),
                        SwitchListTile(
                          title: _title("Documents", isDark),
                          subtitle: _sub("May incur roaming charges.", isDark),
                          value: ctrl.roamingDocuments.value,
                          activeThumbColor: isDark
                              ? Colors.purple[200]
                              : Colors.purple[700],
                          onChanged: ctrl.setRoamingDocuments,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _glass(bool isDark, {required Widget child}) {
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

  Widget _divider(bool isDark) => Divider(
    indent: 60,
    endIndent: 20,
    height: 1,
    color: isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.05),
  );

  Widget _section(String title, bool isDark) => Padding(
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

  Widget _title(String text, bool isDark) => Text(
    text,
    style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 15),
  );

  Widget _sub(String text, bool isDark) => Text(
    text,
    style: TextStyle(
      fontSize: 12,
      color: isDark ? Colors.white38 : Colors.black38,
    ),
  );
}

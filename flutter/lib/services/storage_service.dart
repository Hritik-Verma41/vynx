import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:vynx/models/privacy_settings_model.dart';

class StorageService extends GetxService {
  final _cache = GetStorage();
  final _secure = const FlutterSecureStorage();

  static const String accessKey = 'access_token';
  static const String privacySettingsKey = 'cached_privacy_settings';
  static const String refreshKey = 'refresh_token';
  static const String themeKey = 'app_theme_mode';
  static const String userKey = 'user_cache';

  void writeCache(String key, dynamic value) => _cache.write(key, value);
  T? readCache<T>(String key) => _cache.read<T>(key);
  void removeCache(String key) => _cache.remove(key);

  void savePrivacySettings(PrivacySettingsModel settings) {
    _cache.write(privacySettingsKey, settings.toJson());
  }

  PrivacySettingsModel? getPrivacySettings() {
    final data = _cache.read(privacySettingsKey);
    if (data != null) {
      return PrivacySettingsModel.fromJson(Map<String, dynamic>.from(data));
    }
    return null;
  }

  Future<void> writeSecure(String key, String value) async =>
      await _secure.write(key: key, value: value);

  Future<String?> readSecure(String key) async => await _secure.read(key: key);

  Future<void> clearAll() async {
    await _cache.erase();
    await _secure.deleteAll();
  }

  void saveThemeMode(ThemeMode mode) {
    int index = 0;
    if (mode == ThemeMode.light) index = 1;
    if (mode == ThemeMode.dark) index = 2;
    _cache.write(themeKey, index);
  }

  ThemeMode getThemeMode() {
    int? index = _cache.read<int>(themeKey);
    if (index == 1) return ThemeMode.light;
    if (index == 2) return ThemeMode.dark;
    return ThemeMode.system;
  }
}

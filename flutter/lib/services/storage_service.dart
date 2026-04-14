import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:vynx/models/data_usage_settings_model.dart';
import 'package:vynx/models/notificatio_settings_model.dart';
import 'package:vynx/models/privacy_settings_model.dart';

class StorageService extends GetxService {
  final _cache = GetStorage();
  final _secure = const FlutterSecureStorage();

  static const String accessKey = 'access_token';
  static const String appLockKey = 'app_lock_enabled';
  static const String autoDlMobilePhotosKey = 'auto_dl_mobile_photos';
  static const String autoDlMobileAudioKey = 'auto_dl_mobile_audio';
  static const String autoDlMobileDocsKey = 'auto_dl_mobile_docs';
  static const String autoDlMobileVideosKey = 'auto_dl_mobile_videos';
  static const String autoDlWifiPhotosKey = 'auto_dl_wifi_photos';
  static const String autoDlWifiAudioKey = 'auto_dl_wifi_audio';
  static const String autoDlWifiDocsKey = 'auto_dl_wifi_docs';
  static const String autoDlWifiVideosKey = 'auto_dl_wifi_videos';
  static const String autoDlRoamingPhotosKey = 'auto_dl_roaming_photos';
  static const String autoDlRoamingAudioKey = 'auto_dl_roaming_audio';
  static const String autoDlRoamingDocsKey = 'auto_dl_roaming_docs';
  static const String autoDlRoamingVideosKey = 'auto_dl_roaming_videos';
  static const String dataSaverKey = 'data_saver';
  static const String privacySettingsKey = 'cached_privacy_settings';
  static const String notificationSettingsKey = 'cached_notification_settings';
  static const String dataUsageSettingsKey = 'cached_data_usage_settings';
  static const String cachedContactsKey = 'cached_contacts';
  static const String cachedPhonebookMatchesKey = 'cached_phonebook_matches';
  static const String deviceFcmTokenKey = 'device_fcm_token';
  static const String registeredDeviceFcmTokenKey = 'registered_device_fcm_token';
  static const String notifCallsKey = 'notif_calls';
  static const String notifEnabledKey = 'notif_enabled';
  static const String notifMessagePreviewKey = 'notif_message_preview';
  static const String notifSoundKey = 'notif_sound';
  static const String notifVibrateKey = 'notif_vibrate';
  static const String refreshKey = 'refresh_token';
  static const String themeKey = 'app_theme_mode';
  static const String userKey = 'user_cache';
  static const String wifiOnlySyncKey = 'wifi_only_sync';

  void writeCache(String key, dynamic value) => _cache.write(key, value);
  T? readCache<T>(String key) => _cache.read<T>(key);
  void removeCache(String key) => _cache.remove(key);

  void saveAppLockEnabled(bool enabled) {
    _cache.write(appLockKey, enabled);
  }

  bool getAppLockEnabled() {
    return _cache.read<bool>(appLockKey) ?? false;
  }

  void saveNotificationSettings(NotificationSettingsModel settings) {
    _cache.write(notificationSettingsKey, settings.toJson());
  }

  void savePrivacySettings(PrivacySettingsModel settings) {
    _cache.write(privacySettingsKey, settings.toJson());
  }

  NotificationSettingsModel? getNotificationSettings() {
    final data = _cache.read(notificationSettingsKey);
    if (data != null) {
      return NotificationSettingsModel.fromJson(
        Map<String, dynamic>.from(data),
      );
    }
    return null;
  }

  PrivacySettingsModel? getPrivacySettings() {
    final data = _cache.read(privacySettingsKey);
    if (data != null) {
      return PrivacySettingsModel.fromJson(Map<String, dynamic>.from(data));
    }
    return null;
  }

  void saveDataUsageSettings(DataUsageSettingsModel settings) {
    _cache.write(dataUsageSettingsKey, settings.toJson());
  }

  DataUsageSettingsModel? getDataUsageSettings() {
    final data = _cache.read(dataUsageSettingsKey);
    if (data != null) {
      return DataUsageSettingsModel.fromJson(Map<String, dynamic>.from(data));
    }
    return null;
  }

  void saveContactsCache(List<Map<String, dynamic>> contacts) {
    _cache.write(cachedContactsKey, contacts);
  }

  List<Map<String, dynamic>> getContactsCache() {
    final data = _cache.read(cachedContactsKey);
    if (data is List) {
      return data
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  void savePhonebookMatchesCache(List<Map<String, dynamic>> matches) {
    _cache.write(cachedPhonebookMatchesKey, matches);
  }

  List<Map<String, dynamic>> getPhonebookMatchesCache() {
    final data = _cache.read(cachedPhonebookMatchesKey);
    if (data is List) {
      return data
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  void saveDeviceFcmToken(String token) {
    _cache.write(deviceFcmTokenKey, token);
  }

  String? getDeviceFcmToken() {
    return _cache.read<String>(deviceFcmTokenKey);
  }

  void clearDeviceFcmToken() {
    _cache.remove(deviceFcmTokenKey);
    _cache.remove(registeredDeviceFcmTokenKey);
  }

  void saveRegisteredDeviceFcmToken(String token) {
    _cache.write(registeredDeviceFcmTokenKey, token);
  }

  String? getRegisteredDeviceFcmToken() {
    return _cache.read<String>(registeredDeviceFcmTokenKey);
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

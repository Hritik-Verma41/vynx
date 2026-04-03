import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vynx/config/api_urls.dart';
import 'package:vynx/models/notificatio_settings_model.dart';
import 'package:vynx/services/api_service.dart';
import 'package:vynx/services/storage_service.dart';

class NotificationsSettingsController extends GetxController {
  final Dio _dio = Get.find<ApiService>().dio;
  final StorageService _storage = Get.find<StorageService>();

  var isLoading = false.obs;
  var settings = Rxn<NotificationSettingsModel>();

  @override
  void onInit() {
    super.onInit();
    _loadFromCache();
    fetchSettings();
  }

  void _loadFromCache() {
    final cached = _storage.getNotificationSettings();
    if (cached != null) settings.value = cached;
  }

  Future<void> fetchSettings() async {
    if (settings.value == null) isLoading.value = true;
    try {
      final res = await _dio.get(ApiUrls.notificationSettings);
      if (res.statusCode == 200) {
        final server = NotificationSettingsModel.fromJson(res.data['settings']);
        final local = settings.value;

        if (local == null || server.updatedAt.isAfter(local.updatedAt)) {
          settings.value = server;
          _storage.saveNotificationSettings(server);
        }
      }
    } catch (e) {
      debugPrint("Offline/Error fetching notification settings: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateSetting(String key, dynamic value) async {
    if (settings.value == null) return;

    final now = DateTime.now();
    final updated = settings.value!.toJson();
    updated[key] = value;
    updated['updatedAt'] = now.toIso8601String();

    final localModel = NotificationSettingsModel.fromJson(updated);
    settings.value = localModel;
    _storage.saveNotificationSettings(localModel);

    try {
      final res = await _dio.patch(
        ApiUrls.notificationSettingsUpdate,
        data: {key: value, 'updatedAt': updated['updatedAt']},
      );

      if (res.statusCode == 200) {
        final server = NotificationSettingsModel.fromJson(res.data['settings']);
        settings.value = server;
        _storage.saveNotificationSettings(server);
      }
    } catch (e) {
      Get.snackbar(
        "Offline",
        "Saved locally. We'll sync when you're back online.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.withValues(alpha: 0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    }
  }
}

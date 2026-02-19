import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vynx/config/api_urls.dart';
import 'package:vynx/models/privacy_settings_model.dart';
import 'package:vynx/services/api_service.dart';
import 'package:vynx/services/storage_service.dart';

class PrivacySettingsController extends GetxController {
  final Dio _dio = Get.find<ApiService>().dio;
  final StorageService _storage = Get.find<StorageService>();

  var isLoading = false.obs;
  var privacySettings = Rxn<PrivacySettingsModel>();

  @override
  void onInit() {
    super.onInit();
    _loadFromCache();
    fetchPrivacySettings();
  }

  void _loadFromCache() {
    final cached = _storage.getPrivacySettings();
    if (cached != null) {
      privacySettings.value = cached;
    }
  }

  Future<void> fetchPrivacySettings() async {
    if (privacySettings.value == null) isLoading.value = true;
    try {
      final response = await _dio.get(ApiUrls.privacySettings);
      if (response.statusCode == 200) {
        final serverSettings = PrivacySettingsModel.fromJson(
          response.data['settings'],
        );

        final local = privacySettings.value;
        if (local == null ||
            serverSettings.updatedAt.isAfter(local.updatedAt)) {
          privacySettings.value = serverSettings;
          _storage.savePrivacySettings(serverSettings);
        }
      }
    } catch (e) {
      debugPrint("Offline/Error fetching privacy settings: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updatePrivacySettings(String key, dynamic value) async {
    if (privacySettings.value == null) return;

    final currentJson = privacySettings.value!.toJson();
    currentJson[key] = value;
    final timestamp = DateTime.now().toIso8601String();
    currentJson['updatedAt'] = timestamp;

    final updatedModel = PrivacySettingsModel.fromJson(currentJson);

    privacySettings.value = updatedModel;
    _storage.savePrivacySettings(updatedModel);

    try {
      final response = await _dio.patch(
        ApiUrls.privacySettingsUpdate,
        data: {key: value, 'updatedAt': timestamp},
      );

      if (response.statusCode == 200) {
        final serverSettings = PrivacySettingsModel.fromJson(
          response.data['settings'],
        );
        privacySettings.value = serverSettings;
        _storage.savePrivacySettings(serverSettings);
      }
    } catch (e) {
      Get.snackbar(
        "Offline",
        "Settings saved locally. We'll sync with the server when you're back online.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.withValues(alpha: 0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    }
  }
}

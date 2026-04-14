import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vynx/config/api_urls.dart';
import 'package:vynx/models/data_usage_settings_model.dart';
import 'package:vynx/services/api_service.dart';
import 'package:vynx/services/storage_service.dart';

class DataUsageSettingsController extends GetxController {
  final Dio _dio = Get.find<ApiService>().dio;
  final StorageService _storage = Get.find<StorageService>();

  var isLoading = false.obs;
  var settings = Rxn<DataUsageSettingsModel>();

  @override
  void onInit() {
    super.onInit();
    _loadFromCache();
    fetchSettings();
  }

  void _loadFromCache() {
    final cached = _storage.getDataUsageSettings();
    if (cached != null) {
      settings.value = cached;
      _syncObservablesFromModel(cached);
    }
  }

  void _syncObservablesFromModel(DataUsageSettingsModel model) {
    dataSaver.value = model.dataSaver;
    mobilePhotos.value = model.mobilePhotos;
    mobileVideos.value = model.mobileVideos;
    mobileAudio.value = model.mobileAudio;
    mobileDocuments.value = model.mobileDocuments;
    wifiPhotos.value = model.wifiPhotos;
    wifiVideos.value = model.wifiVideos;
    wifiAudio.value = model.wifiAudio;
    wifiDocuments.value = model.wifiDocuments;
    roamingPhotos.value = model.roamingPhotos;
    roamingVideos.value = model.roamingVideos;
    roamingAudio.value = model.roamingAudio;
    roamingDocuments.value = model.roamingDocuments;
  }

  Future<void> fetchSettings() async {
    if (settings.value == null) isLoading.value = true;
    try {
      final res = await _dio.get(ApiUrls.dataUsageSettings);
      if (res.statusCode == 200) {
        final server = DataUsageSettingsModel.fromJson(res.data['settings']);
        final local = settings.value;

        if (local == null || server.updatedAt.isAfter(local.updatedAt)) {
          settings.value = server;
          _storage.saveDataUsageSettings(server);
          _syncObservablesFromModel(server);
        }
      }
    } catch (e) {
      debugPrint("Offline/Error fetching data usage settings: $e");
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

    final localModel = DataUsageSettingsModel.fromJson(updated);
    settings.value = localModel;
    _storage.saveDataUsageSettings(localModel);
    _syncObservablesFromModel(localModel);

    try {
      final res = await _dio.patch(
        ApiUrls.dataUsageSettingsUpdate,
        data: {key: value, 'updatedAt': updated['updatedAt']},
      );

      if (res.statusCode == 200) {
        final server = DataUsageSettingsModel.fromJson(res.data['settings']);
        settings.value = server;
        _storage.saveDataUsageSettings(server);
        _syncObservablesFromModel(server);
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

  // Observable properties for UI binding
  final dataSaver = false.obs;
  final mobilePhotos = true.obs;
  final mobileVideos = false.obs;
  final mobileAudio = false.obs;
  final mobileDocuments = false.obs;
  final wifiPhotos = true.obs;
  final wifiVideos = true.obs;
  final wifiAudio = true.obs;
  final wifiDocuments = true.obs;
  final roamingPhotos = false.obs;
  final roamingVideos = false.obs;
  final roamingAudio = false.obs;
  final roamingDocuments = false.obs;

  // Setters with sync
  void setDataSaver(bool v) {
    updateSetting('dataSaver', v);
    if (v) {
      updateSetting('mobileVideos', false);
      updateSetting('mobileAudio', false);
      updateSetting('mobileDocuments', false);
    }
  }

  void setMobilePhotos(bool v) => updateSetting('mobilePhotos', v);
  void setMobileVideos(bool v) => updateSetting('mobileVideos', v);
  void setMobileAudio(bool v) => updateSetting('mobileAudio', v);
  void setMobileDocuments(bool v) => updateSetting('mobileDocuments', v);
  void setWifiPhotos(bool v) => updateSetting('wifiPhotos', v);
  void setWifiVideos(bool v) => updateSetting('wifiVideos', v);
  void setWifiAudio(bool v) => updateSetting('wifiAudio', v);
  void setWifiDocuments(bool v) => updateSetting('wifiDocuments', v);
  void setRoamingPhotos(bool v) => updateSetting('roamingPhotos', v);
  void setRoamingVideos(bool v) => updateSetting('roamingVideos', v);
  void setRoamingAudio(bool v) => updateSetting('roamingAudio', v);
  void setRoamingDocuments(bool v) => updateSetting('roamingDocuments', v);
}
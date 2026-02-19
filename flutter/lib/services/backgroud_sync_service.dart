import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vynx/config/api_urls.dart';
import 'package:vynx/models/privacy_settings_model.dart';
import 'package:vynx/services/api_service.dart';
import 'package:vynx/services/storage_service.dart';

class BackgroudSyncService extends GetxService {
  final Dio _dio = Get.find<ApiService>().dio;
  final StorageService _storage = Get.find<StorageService>();
  StreamSubscription? _connectivitySubscription;

  @override
  void onInit() {
    super.onInit();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      if (results.any((result) => result != ConnectivityResult.none)) {
        debugPrint("Network available: Triggering Sync...");
        syncPrivacySettings();
      }
    });
  }

  @override
  void onClose() {
    _connectivitySubscription?.cancel();
    super.onClose();
  }

  Future<void> syncPrivacySettings() async {
    try {
      final response = await _dio.get(ApiUrls.privacySettings);
      final serverSettings = PrivacySettingsModel.fromJson(
        response.data['settings'],
      );

      final localSettings = _storage.getPrivacySettings();

      if (localSettings == null) {
        _storage.savePrivacySettings(serverSettings);
        return;
      }

      if (localSettings.updatedAt.isAfter(serverSettings.updatedAt)) {
        await _dio.patch(
          ApiUrls.privacySettingsUpdate,
          data: localSettings.toJson(),
        );
        debugPrint("Global Sync: Pushed local changes to server.");
      } else if (serverSettings.updatedAt.isAfter(localSettings.updatedAt)) {
        _storage.savePrivacySettings(serverSettings);
        debugPrint("Global Sync: Updated local cache from server.");
      }
    } catch (e) {
      debugPrint("Global Sync: Failed or Offline. Will try next launch.");
    }
  }
}

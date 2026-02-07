import 'dart:developer';

import 'package:get/get.dart';
import 'package:vynx/models/user_model.dart';
import 'package:vynx/routes/app_routes.dart';
import 'package:vynx/services/api_service.dart';
import 'package:vynx/services/storage_service.dart';

class UserController extends GetxController {
  final _storage = Get.find<StorageService>();
  final _dio = Get.find<ApiService>().dio;

  final user = Rxn<UserModel>();
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeUser();
  }

  void _initializeUser() {
    final cachedData = _storage.readCache(StorageService.userKey);
    if (cachedData != null) {
      user.value = UserModel.fromJson(cachedData);
    }

    fetchProfile();
  }

  Future<void> fetchProfile() async {
    try {
      isLoading.value = true;
      final response = await _dio.get('/auth/profile');

      if (response.statusCode == 200 && response.data['user'] != null) {
        final fetchedUser = UserModel.fromJson(response.data['user']);
        user.value = fetchedUser;
        _storage.writeCache(StorageService.userKey, fetchedUser.toJson());
        log("User loaded: ${fetchedUser.firstName}");
      } else {
        log("Profile fetch returned 200 but no user data found.");
      }
    } catch (e) {
      log("Profile Sync Error: $e");
      if (user.value == null) {
        final cachedData = _storage.readCache(StorageService.userKey);
        if (cachedData != null) user.value = UserModel.fromJson(cachedData);
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    await _storage.clearAll();

    Get.delete<UserController>(force: true);
    Get.offAllNamed(Routes.login);
  }
}

import 'package:get/get.dart';
import 'package:vynx/services/storage_service.dart';

class TokenService extends GetxService {
  final _storage = Get.find<StorageService>();

  bool isUserLoggedIn = false;

  Future<void> saveTokens(String access, String refresh) async {
    isUserLoggedIn = true;
    await _storage.writeSecure(StorageService.accessKey, access);
    await _storage.writeSecure(StorageService.refreshKey, refresh);
  }

  Future<String?> getAccessToken() =>
      _storage.readSecure(StorageService.accessKey);
  Future<String?> getRefreshToken() async {
    String? token = await _storage.readSecure(StorageService.refreshKey);
    isUserLoggedIn = token != null;
    return token;
  }

  Future<void> clearTokens() async => await _storage.clearAll();
}

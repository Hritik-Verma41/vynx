import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

class TokenService extends GetxService {
  final _storage = const FlutterSecureStorage();

  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  bool isUserLoggedIn = false;

  Future<void> saveTokens(String access, String refresh) async {
    isUserLoggedIn = true;
    await _storage.write(key: _accessKey, value: access);
    await _storage.write(key: _refreshKey, value: refresh);
  }

  Future<String?> getAccessToken() => _storage.read(key: _accessKey);
  Future<String?> getRefreshToken() async {
    String? token = await _storage.read(key: 'refresh_token');
    isUserLoggedIn = token != null;
    return token;
  }

  Future<void> clearTokens() async => await _storage.deleteAll();
}

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class StorageService extends GetxService {
  final _cache = GetStorage();
  final _secure = const FlutterSecureStorage();

  static const String userKey = 'user_cache';
  static const String accessKey = 'access_token';
  static const String refreshKey = 'refresh_token';

  void writeCache(String key, dynamic value) => _cache.write(key, value);
  T? readCache<T>(String key) => _cache.read<T>(key);
  void removeCache(String key) => _cache.remove(key);

  Future<void> writeSecure(String key, String value) async =>
      await _secure.write(key: key, value: value);

  Future<String?> readSecure(String key) async => await _secure.read(key: key);

  Future<void> clearAll() async {
    await _cache.erase();
    await _secure.deleteAll();
  }
}

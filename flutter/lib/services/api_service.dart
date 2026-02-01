import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:get/get.dart';

class ApiService extends GetxService {
  late Dio _dio;

  Dio get dio => _dio;

  @override
  void onInit() {
    super.onInit();
    _initalizeDio();
  }

  void _initalizeDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: "http://localhost:8000/api",
        connectTimeout: Duration(seconds: 10),
        receiveTimeout: Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          log("🚀 REQUEST[${options.method}] => PATH: ${options.path}");
          return handler.next(options);
        },
        onResponse: (response, handler) {
          log("✅ RESPONSE[${response.statusCode}]");
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          log("❌ ERROR[${e.response?.statusCode}] => MESSAGE: ${e.message}");
          return handler.next(e);
        },
      ),
    );
  }
}

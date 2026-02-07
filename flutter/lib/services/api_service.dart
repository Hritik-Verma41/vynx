import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:vynx/routes/app_routes.dart';
import 'package:vynx/services/token_service.dart';
import 'package:vynx/widgets/vynx_alert_popup.dart';

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
      ),
    );

    void _handleLogoutConflict() {
      Get.find<TokenService>().clearTokens();
      Get.dialog(
        VynxAlertPopup(
          title: "Session Conflict",
          message:
              "You have been logged in on another device. Please log in again to continue.",
          onConfirm: () => Get.offAllNamed(Routes.login),
        ),
        barrierDismissible: false,
      );
    }

    Future<void> _retryWithRefresh(
      DioException e,
      ErrorInterceptorHandler handler,
    ) async {
      final refreshToken = await Get.find<TokenService>().getRefreshToken();
      if (refreshToken == null) return handler.next(e);

      try {
        final refreshRes = await Dio().post(
          "http://localhost:8000/api/auth/refresh-token",
          data: {'refreshToken': refreshToken},
        );

        if (refreshRes.statusCode == 200) {
          final retryResponse = await _dio.fetch(e.requestOptions);
          return handler.resolve(retryResponse);
        }
      } catch (err) {
        _handleLogoutConflict();
      }
    }

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await Get.find<TokenService>().getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          log("🚀 REQUEST[${options.method}] => PATH: ${options.path}");
          return handler.next(options);
        },
        onResponse: (response, handler) async {
          final access = response.headers
              .value('Authorization')
              ?.replaceFirst('Bearer ', '');
          final refresh = response.headers.value('x-refresh-token');

          if (access != null && refresh != null) {
            await Get.find<TokenService>().saveTokens(access, refresh);
          }

          return handler.next(response);
        },
        onError: (DioException e, handler) {
          if (e.response?.statusCode == 401) {
            _retryWithRefresh(e, handler);
            return;
          }
          if (e.response?.statusCode == 403) {
            _handleLogoutConflict();
            return;
          }
          return handler.next(e);
        },
      ),
    );
  }
}

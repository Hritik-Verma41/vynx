import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:vynx/config/api_urls.dart';
import 'package:vynx/config/env_config.dart';
import 'package:vynx/routes/app_routes.dart';
import 'package:vynx/services/token_service.dart';
import 'package:vynx/widgets/vynx_alert_popup.dart';

class ApiService extends GetxService {
  late Dio _dio;
  Future<bool>? _refreshInFlight;
  bool _isSessionDialogShowing = false;

  Dio get dio => _dio;

  @override
  void onInit() {
    super.onInit();
    _initalizeDio();
  }

  void _initalizeDio() {
    String baseUrl = EnvConfig.instance.baseUrl;

    _dio = Dio(
      BaseOptions(baseUrl: baseUrl, connectTimeout: Duration(seconds: 10)),
    );

    Future<void> handleLogoutConflict() async {
      await Get.find<TokenService>().clearTokens();

      // If we're already on the login screen, don't force a route reset.
      if (Get.currentRoute == Routes.login) {
        if (Get.isDialogOpen ?? false) {
          Get.back();
        }
        return;
      }

      if (_isSessionDialogShowing) return;
      _isSessionDialogShowing = true;

      Get.dialog(
        VynxAlertPopup(
          title: "Session Conflict",
          message:
              "You have been logged in on another device. Please log in again to continue.",
          confirmBtnText: 'Back to Login',
          onConfirm: () {
            if (Get.isDialogOpen ?? false) Get.back();
            if (Get.currentRoute != Routes.login) {
              Get.offAllNamed(Routes.login);
            }
          },
        ),
        barrierDismissible: false,
      ).whenComplete(() => _isSessionDialogShowing = false);
    }

    Future<bool> refreshTokens() {
      return _refreshInFlight ??= () async {
        try {
          final tokenService = Get.find<TokenService>();
          final refreshToken = await tokenService.getRefreshToken();
          if (refreshToken == null) return false;

          final refreshDio = Dio(
            BaseOptions(
              baseUrl: _dio.options.baseUrl,
              connectTimeout: _dio.options.connectTimeout,
              receiveTimeout: _dio.options.receiveTimeout,
              sendTimeout: _dio.options.sendTimeout,
            ),
          );

          final refreshRes = await refreshDio.post(
            ApiUrls.refreshToken,
            data: {'refreshToken': refreshToken},
          );

          if (refreshRes.statusCode != 200) return false;

          final access = refreshRes.headers
              .value('Authorization')
              ?.replaceFirst('Bearer ', '');
          final refresh = refreshRes.headers.value('x-refresh-token');
          if (access != null && refresh != null) {
            await tokenService.saveTokens(access, refresh);
            return true;
          }

          return false;
        } catch (_) {
          return false;
        } finally {
          _refreshInFlight = null;
        }
      }();
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
        onError: (DioException e, handler) async {
          final int? status = e.response?.statusCode;

          if (status == 403) {
            await handleLogoutConflict();
            return handler.next(e);
          }

          if (status != 401) return handler.next(e);

          final path = e.requestOptions.path;
          if (path.endsWith(ApiUrls.authLogin) ||
              path.endsWith(ApiUrls.authSignup) ||
              path.endsWith(ApiUrls.refreshToken)) {
            return handler.next(e);
          }

          final refreshToken = await Get.find<TokenService>().getRefreshToken();
          if (refreshToken == null) {
            // Not logged in (or tokens cleared). Treat as a normal 401.
            return handler.next(e);
          }

          // If refresh itself fails, don't recursively attempt to refresh.
          if (e.requestOptions.path.endsWith(ApiUrls.refreshToken)) {
            await handleLogoutConflict();
            return handler.next(e);
          }

          const retryKey = '__vynx_retried';
          if (e.requestOptions.extra[retryKey] == true) {
            return handler.next(e);
          }

          final refreshed = await refreshTokens();
          if (!refreshed) {
            await handleLogoutConflict();
            return handler.next(e);
          }

          final newAccess = await Get.find<TokenService>().getAccessToken();
          e.requestOptions.extra[retryKey] = true;
          if (newAccess != null) {
            e.requestOptions.headers['Authorization'] = 'Bearer $newAccess';
          }

          try {
            final retryResponse = await _dio.fetch(e.requestOptions);
            return handler.resolve(retryResponse);
          } catch (_) {
            return handler.next(e);
          }
        },
      ),
    );
  }
}

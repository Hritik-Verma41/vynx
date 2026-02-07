import 'dart:async';
import 'dart:developer';
import 'package:get/get.dart';
import 'package:vynx/services/api_service.dart';
import 'package:vynx/services/token_service.dart';

class AuthTimerService extends GetxService {
  Timer? _refreshTimer;
  final _tokenService = Get.find<TokenService>();

  void startTokenTimer() {
    _refreshTimer?.cancel();

    refreshSession();

    _refreshTimer = Timer.periodic(const Duration(minutes: 14), (timer) async {
      log("Scheduled Token Refresh Triggered...");
      await refreshSession();
    });
  }

  Future<void> refreshSession() async {
    try {
      final refreshToken = await _tokenService.getRefreshToken();
      if (refreshToken == null) return;

      final response = await Get.find<ApiService>().dio.post(
        "/auth/refresh-token",
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        log("Background Token Refresh Successful");
      }
    } catch (e) {
      log("Background Refresh Failed: $e");
    }
  }

  void stopTimer() {
    _refreshTimer?.cancel();
    log("Token Refresh Timer Stopped");
  }

  @override
  void onClose() {
    stopTimer();
    super.onClose();
  }
}

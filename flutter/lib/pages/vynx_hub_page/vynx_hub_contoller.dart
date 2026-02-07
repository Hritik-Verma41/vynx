import 'package:get/get.dart';
import 'package:vynx/services/auth_timer_service.dart';

class VynxHubController extends GetxController {
  var currentIndex = 0.obs;
  final _authTimer = Get.put(AuthTimerService());

  @override
  void onInit() {
    super.onInit();
    _authTimer.startTokenTimer();
  }

  void changeTab(int index) {
    currentIndex.value = index;
  }

  @override
  void onClose() {
    _authTimer.stopTimer();
    super.onClose();
  }
}

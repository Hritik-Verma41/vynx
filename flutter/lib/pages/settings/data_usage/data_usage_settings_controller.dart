import 'package:get/get.dart';
import 'package:vynx/services/storage_service.dart';

class DataUsageSettingsController extends GetxController {
  final StorageService _storage = Get.find<StorageService>();

  final dataSaver = false.obs;

  final mobilePhotos = true.obs;
  final mobileVideos = false.obs;
  final mobileAudio = false.obs;
  final mobileDocuments = false.obs;

  final wifiPhotos = true.obs;
  final wifiVideos = true.obs;
  final wifiAudio = true.obs;
  final wifiDocuments = true.obs;

  final roamingPhotos = false.obs;
  final roamingVideos = false.obs;
  final roamingAudio = false.obs;
  final roamingDocuments = false.obs;

  bool _readBool(String key, bool fallback) =>
      _storage.readCache(key) ?? fallback;

  void _writeBool(String key, bool value) => _storage.writeCache(key, value);

  @override
  void onInit() {
    super.onInit();

    dataSaver.value = _readBool(StorageService.dataSaverKey, false);

    mobilePhotos.value = _readBool(StorageService.autoDlMobilePhotosKey, true);
    mobileVideos.value = _readBool(StorageService.autoDlMobileVideosKey, false);
    mobileAudio.value = _readBool(StorageService.autoDlMobileAudioKey, false);
    mobileDocuments.value = _readBool(
      StorageService.autoDlMobileDocsKey,
      false,
    );

    wifiPhotos.value = _readBool(StorageService.autoDlWifiPhotosKey, true);
    wifiVideos.value = _readBool(StorageService.autoDlWifiVideosKey, true);
    wifiAudio.value = _readBool(StorageService.autoDlWifiAudioKey, true);
    wifiDocuments.value = _readBool(StorageService.autoDlWifiDocsKey, true);

    roamingPhotos.value = _readBool(
      StorageService.autoDlRoamingPhotosKey,
      false,
    );
    roamingVideos.value = _readBool(
      StorageService.autoDlRoamingVideosKey,
      false,
    );
    roamingAudio.value = _readBool(StorageService.autoDlRoamingAudioKey, false);
    roamingDocuments.value = _readBool(
      StorageService.autoDlRoamingDocsKey,
      false,
    );
  }

  void setDataSaver(bool v) {
    dataSaver.value = v;
    _writeBool(StorageService.dataSaverKey, v);

    if (v) {
      mobileVideos.value = false;
      mobileAudio.value = false;
      mobileDocuments.value = false;
      _writeBool(StorageService.autoDlMobileVideosKey, false);
      _writeBool(StorageService.autoDlMobileAudioKey, false);
      _writeBool(StorageService.autoDlMobileDocsKey, false);
    }
  }

  void setMobilePhotos(bool v) {
    mobilePhotos.value = v;
    _writeBool(StorageService.autoDlMobilePhotosKey, v);
  }

  void setMobileVideos(bool v) {
    mobileVideos.value = v;
    _writeBool(StorageService.autoDlMobileVideosKey, v);
  }

  void setMobileAudio(bool v) {
    mobileAudio.value = v;
    _writeBool(StorageService.autoDlMobileAudioKey, v);
  }

  void setMobileDocuments(bool v) {
    mobileDocuments.value = v;
    _writeBool(StorageService.autoDlMobileDocsKey, v);
  }

  void setWifiPhotos(bool v) {
    wifiPhotos.value = v;
    _writeBool(StorageService.autoDlWifiPhotosKey, v);
  }

  void setWifiVideos(bool v) {
    wifiVideos.value = v;
    _writeBool(StorageService.autoDlWifiVideosKey, v);
  }

  void setWifiAudio(bool v) {
    wifiAudio.value = v;
    _writeBool(StorageService.autoDlWifiAudioKey, v);
  }

  void setWifiDocuments(bool v) {
    wifiDocuments.value = v;
    _writeBool(StorageService.autoDlWifiDocsKey, v);
  }

  void setRoamingPhotos(bool v) {
    roamingPhotos.value = v;
    _writeBool(StorageService.autoDlRoamingPhotosKey, v);
  }

  void setRoamingVideos(bool v) {
    roamingVideos.value = v;
    _writeBool(StorageService.autoDlRoamingVideosKey, v);
  }

  void setRoamingAudio(bool v) {
    roamingAudio.value = v;
    _writeBool(StorageService.autoDlRoamingAudioKey, v);
  }

  void setRoamingDocuments(bool v) {
    roamingDocuments.value = v;
    _writeBool(StorageService.autoDlRoamingDocsKey, v);
  }
}

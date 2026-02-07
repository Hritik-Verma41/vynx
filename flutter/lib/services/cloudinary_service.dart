import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:vynx/services/api_service.dart';

class CloudinaryService {
  static const String _cloudName = "dvltyb4hb";
  static const String _uploadPreset = "vynx_app_preset";
  static const String _baseUrl =
      "https://api.cloudinary.com/v1_1/$_cloudName/image/upload";

  final Dio _cloudinaryDio = Dio();

  Future<Map<String, String>?> uploadImage({
    String? filePath,
    String? networkUrl,
    Uint8List? assetBytes,
    String? assetName,
  }) async {
    try {
      FormData formData = FormData();
      formData.fields.add(const MapEntry('upload_preset', _uploadPreset));

      if (filePath != null) {
        formData.files.add(
          MapEntry('file', await MultipartFile.fromFile(filePath)),
        );
      } else if (networkUrl != null) {
        formData.fields.add(MapEntry('file', networkUrl));
      } else if (assetBytes != null) {
        formData.files.add(
          MapEntry(
            'file',
            MultipartFile.fromBytes(
              assetBytes,
              filename: assetName ?? 'asset_image.png',
            ),
          ),
        );
      }

      final response = await _cloudinaryDio.post(_baseUrl, data: formData);

      if (response.statusCode == 200) {
        return {
          'url': response.data['secure_url'] as String,
          'public_id': response.data['public_id'] as String,
        };
      }
    } catch (e) {
      log('Cloudinary Service Error: $e');
    }
    return null;
  }

  Future<void> deleteImage(String publicId) async {
    try {
      log("🧹 Cleaning up Cloudinary image: $publicId");

      final backendDio = Get.find<ApiService>().dio;

      await backendDio.post(
        '/utils/delete-image',
        data: {'publicId': publicId},
      );

      log("✅ Cleanup request sent successfully");
    } catch (e) {
      log('Cloudinary Delete Error: $e');
    }
  }
}

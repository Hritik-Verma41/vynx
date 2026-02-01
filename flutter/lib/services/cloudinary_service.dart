import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class CloudinaryService {
  static const String _cloudName = "dvltyb4hb";
  static const String _uploadPreset = "vynx_app_preset";
  static const String _baseUrl =
      "https://api.cloudinary.com/v1_1/$_cloudName/image/upload";

  final Dio _dio = Dio();

  Future<String?> uploadImage({
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

      final respone = await _dio.post(_baseUrl, data: formData);

      if (respone.statusCode == 200) {
        return respone.data['secure_url'];
      }
    } catch (e) {
      log('Cloudinary Service Error: $e');
    }
    return null;
  }
}

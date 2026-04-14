import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:vynx/config/api_urls.dart';
import 'package:vynx/models/contact_model.dart';
import 'package:vynx/models/conversation_preview_model.dart';
import 'package:vynx/services/api_service.dart';
import 'package:vynx/services/chat_socket_service.dart';

class CreateGroupController extends GetxController {
  final Dio _dio = Get.find<ApiService>().dio;
  final ChatSocketService _socket = Get.find<ChatSocketService>();

  final contacts = <ContactModel>[].obs;
  final selectedIds = <String>{}.obs;
  final isLoading = false.obs;
  final groupName = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchContacts();
  }

  Future<void> fetchContacts() async {
    try {
      isLoading.value = true;
      final res = await _dio.get(ApiUrls.contacts);
      if (res.statusCode == 200) {
        final list = (res.data['contacts'] as List?) ?? [];
        contacts.value = list
            .map((e) => ContactModel.fromJson(Map<String, dynamic>.from(e)))
            .where((c) => c.isAccepted)
            .toList();
      }
    } catch (e) {
      log('fetchContacts in create group error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void toggle(String userId) {
    final next = Set<String>.from(selectedIds);
    if (next.contains(userId)) {
      next.remove(userId);
    } else {
      next.add(userId);
    }
    selectedIds
      ..clear()
      ..addAll(next);
  }

  Future<ConversationPreviewModel?> createGroup() async {
    if (groupName.value.trim().length < 2 || selectedIds.length < 2) return null;

    final ack = await _socket.emitWithAck(
      'conversation:create_group',
      payload: {
        'name': groupName.value.trim(),
        'memberIds': selectedIds.toList(),
      },
    );

    if (ack['success'] == true && ack['conversation'] is Map) {
      return ConversationPreviewModel.fromJson(
        Map<String, dynamic>.from(ack['conversation']),
      );
    }
    Get.snackbar('Group', ack['message']?.toString() ?? 'Failed to create group');
    return null;
  }
}

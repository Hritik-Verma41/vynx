import 'dart:developer';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:vynx/config/api_urls.dart';
import 'package:vynx/controllers/user_controller.dart';
import 'package:vynx/models/contact_model.dart';
import 'package:vynx/models/conversation_preview_model.dart';
import 'package:vynx/services/api_service.dart';
import 'package:vynx/services/chat_socket_service.dart';

class ChatsController extends GetxController {
  final Dio _dio = Get.find<ApiService>().dio;
  final ChatSocketService _socket = Get.find<ChatSocketService>();

  final conversations = <ConversationPreviewModel>[].obs;
  final isLoading = false.obs;
  final query = ''.obs;
  StreamSubscription<Map<String, dynamic>>? _socketSub;

  @override
  void onInit() {
    super.onInit();
    fetchConversations();
    _bindSocket();
  }

  void _bindSocket() {
    _socketSub = _socket.events.listen((evt) {
      final event = evt['event']?.toString() ?? '';
      if (event == 'conversation:updated' || event == 'conversation:created') {
        fetchConversations();
      }
    });
  }

  Future<void> fetchConversations() async {
    try {
      isLoading.value = true;
      final res = await _dio.get(ApiUrls.conversations);
      if (res.statusCode == 200) {
        final List list = (res.data['conversations'] as List?) ?? [];
        conversations.value = list
            .map(
              (e) => ConversationPreviewModel.fromJson(
                Map<String, dynamic>.from(e),
              ),
            )
            .toList();
      }
    } catch (e) {
      log("fetchConversations error: $e");
      conversations.clear();
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    _socketSub?.cancel();
    super.onClose();
  }

  List<ConversationPreviewModel> get filtered {
    final q = query.value.trim().toLowerCase();
    if (q.isEmpty) return conversations;

    final myId = Get.find<UserController>().user.value?.id ?? '';
    return conversations.where((c) {
      if (c.type == 'group') {
        final groupName = (c.name ?? '').toLowerCase();
        final last = (c.lastMessage ?? '').toLowerCase();
        return groupName.contains(q) || last.contains(q);
      }
      final ContactUserModel? peer = c.members
          .where((m) => m.id != myId)
          .cast<ContactUserModel?>()
          .firstOrNull;
      final name = (peer?.fullName ?? '').toLowerCase();
      final last = (c.lastMessage ?? '').toLowerCase();
      return name.contains(q) || last.contains(q);
    }).toList();
  }
}

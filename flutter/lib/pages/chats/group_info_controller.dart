import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:vynx/config/api_urls.dart';
import 'package:vynx/controllers/user_controller.dart';
import 'package:vynx/models/contact_model.dart';
import 'package:vynx/models/conversation_preview_model.dart';
import 'package:vynx/services/api_service.dart';
import 'package:vynx/services/cloudinary_service.dart';

class GroupInfoController extends GetxController {
  final Dio _dio = Get.find<ApiService>().dio;
  final CloudinaryService _cloudinary = Get.find<CloudinaryService>();
  final current = Rxn<ConversationPreviewModel>();
  final members = <ContactUserModel>[].obs;
  final adminIds = <String>{}.obs;
  final isLoading = false.obs;
  final isSaving = false.obs;

  String get myId => Get.find<UserController>().user.value?.id ?? '';
  bool get amIAdmin => adminIds.contains(myId);

  @override
  void onInit() {
    super.onInit();
    current.value = Get.arguments as ConversationPreviewModel?;
    if (current.value != null) {
      fetch();
    }
  }

  Future<void> fetch() async {
    final c = current.value;
    if (c == null) return;
    try {
      isLoading.value = true;
      final res = await _dio.get('${ApiUrls.conversations}/${c.id}');
      if (res.statusCode == 200) {
        final conv = Map<String, dynamic>.from(res.data['conversation']);
        current.value = ConversationPreviewModel.fromJson(conv);
        final rawMembers = (conv['members'] as List?) ?? const [];
        members.value = rawMembers
            .map((e) => ContactUserModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        final rawAdmins = (conv['admins'] as List?) ?? const [];
        adminIds
          ..clear()
          ..addAll(
            rawAdmins
                .map((e) => Map<String, dynamic>.from(e)['_id']?.toString() ?? '')
                .where((id) => id.isNotEmpty),
          );
      }
    } catch (e) {
      log('group info fetch error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateGroup({
    String? name,
    String? description,
    String? avatarFilePath,
  }) async {
    final c = current.value;
    if (c == null || !amIAdmin) return;
    try {
      isSaving.value = true;
      String? avatarUrl;
      if (avatarFilePath != null && avatarFilePath.isNotEmpty) {
        final uploaded = await _cloudinary.uploadImage(filePath: avatarFilePath);
        avatarUrl = uploaded?['url'];
      }
      final payload = <String, dynamic>{};
      if (name != null) payload['name'] = name;
      if (description != null) payload['description'] = description;
      if (avatarUrl != null) payload['avatar'] = avatarUrl;
      if (payload.isEmpty) return;

      await _dio.patch('${ApiUrls.conversations}/${c.id}/group', data: payload);
      await fetch();
    } catch (e) {
      Get.snackbar('Group', 'Failed to update group.');
      log('update group error: $e');
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> addMembers(List<String> memberIds) async {
    final c = current.value;
    if (c == null || !amIAdmin || memberIds.isEmpty) return;
    try {
      await _dio.post(
        '${ApiUrls.conversations}/${c.id}/group/members',
        data: {'memberIds': memberIds},
      );
      await fetch();
    } catch (_) {
      Get.snackbar('Group', 'Failed to add members.');
    }
  }

  Future<void> removeMember(String memberId) async {
    final c = current.value;
    if (c == null) return;
    try {
      await _dio.delete(
        '${ApiUrls.conversations}/${c.id}/group/members/$memberId',
      );
      await fetch();
    } catch (_) {
      Get.snackbar('Group', 'Failed to remove member.');
    }
  }

  Future<void> leaveGroup() async {
    await removeMember(myId);
    Get.back();
  }

  List<ContactUserModel> findAllAcceptedContacts() {
    return _allAcceptedContacts;
  }

  final _allAcceptedContacts = <ContactUserModel>[];

  @override
  void onReady() {
    super.onReady();
    _fetchAllAcceptedContacts();
  }

  Future<void> _fetchAllAcceptedContacts() async {
    try {
      final res = await _dio.get(ApiUrls.contacts);
      if (res.statusCode == 200) {
        final list = (res.data['contacts'] as List?) ?? [];
        _allAcceptedContacts
          ..clear()
          ..addAll(
            list
                .map((e) => ContactModel.fromJson(Map<String, dynamic>.from(e)))
                .where((c) => c.isAccepted)
                .map((c) => c.contactUser),
          );
      }
    } catch (e) {
      log('fetch accepted contacts for group add error: $e');
    }
  }
}

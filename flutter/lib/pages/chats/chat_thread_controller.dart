import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vynx/config/api_urls.dart';
import 'package:vynx/controllers/user_controller.dart';
import 'package:vynx/models/chat_message_model.dart';
import 'package:vynx/models/conversation_preview_model.dart';
import 'package:vynx/services/api_service.dart';
import 'package:vynx/services/chat_socket_service.dart';
import 'package:vynx/services/cloudinary_service.dart';

class ChatThreadController extends GetxController {
  final Dio _dio = Get.find<ApiService>().dio;
  final ChatSocketService _socket = Get.find<ChatSocketService>();
  final CloudinaryService _cloudinary = Get.find<CloudinaryService>();
  final ImagePicker _picker = ImagePicker();

  final messages = <ChatMessageModel>[].obs;
  final textController = TextEditingController();
  final isLoading = false.obs;
  final isSending = false.obs;
  final typingUserIds = <String>{}.obs;

  late final ConversationPreviewModel conversation;
  late final String myUserId;
  StreamSubscription<Map<String, dynamic>>? _socketSub;
  Timer? _typingDebounce;

  @override
  void onInit() {
    super.onInit();
    conversation = Get.arguments as ConversationPreviewModel;
    myUserId = Get.find<UserController>().user.value?.id ?? '';
    _socket.connect();
    fetchMessages();
    _bindSocket();
  }

  Future<void> fetchMessages() async {
    try {
      isLoading.value = true;
      final res = await _dio.get(
        '${ApiUrls.conversations}/${conversation.id}/messages',
      );
      if (res.statusCode == 200) {
        final raw = (res.data['messages'] as List?) ?? [];
        messages.value = raw
            .map((e) => ChatMessageModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        for (final m in messages) {
          final isIncoming = m.senderId != myUserId;
          final alreadyRead = m.readBy.contains(myUserId);
          if (isIncoming && !alreadyRead) {
            _socket.emitWithAck(
              'message:read',
              payload: {'messageId': m.id},
              timeout: const Duration(seconds: 4),
            );
          }
        }
      }
    } catch (e) {
      log('fetchMessages error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _bindSocket() {
    _socketSub = _socket.events.listen((evt) {
      final event = evt['event']?.toString() ?? '';
      final payload = Map<String, dynamic>.from(evt['payload'] ?? {});

      if (event == 'message:new') {
        final msg = ChatMessageModel.fromJson(payload);
        if (msg.conversationId == conversation.id) {
          messages.removeWhere((m) => m.id == msg.id);
          messages.add(msg);
        }
      } else if (event == 'message:deleted') {
        final conversationId = payload['conversationId']?.toString();
        if (conversationId == conversation.id) {
          final messageId = payload['messageId']?.toString() ?? '';
          messages.removeWhere((m) => m.id == messageId);
        }
      } else if (event == 'poll:updated') {
        final messageId = payload['messageId']?.toString() ?? '';
        final poll = payload['poll'];
        if (poll is Map) {
          final idx = messages.indexWhere((m) => m.id == messageId);
          if (idx != -1) {
            final old = messages[idx];
            final updated = ChatMessageModel.fromJson({
              '_id': old.id,
              'conversation': old.conversationId,
              'sender': old.senderId,
              'recipient': old.recipientId,
              'recipients': old.recipients,
              'kind': old.kind,
              'text': old.text,
              'file': old.file?.toJson(),
              'location': old.location?.toJson(),
              'sharedContact': old.sharedContact?.toJson(),
              'event': old.event?.toJson(),
              'poll': poll,
              'deliveredTo': old.deliveredTo,
              'readBy': old.readBy,
              'downloadedBy': old.downloadedBy,
              'createdAt': old.createdAt?.toIso8601String(),
            });
            messages[idx] = updated;
          }
        }
      } else if (event == 'typing:start') {
        final conversationId = payload['conversationId']?.toString() ?? '';
        final userId = payload['userId']?.toString() ?? '';
        if (conversationId == conversation.id &&
            userId.isNotEmpty &&
            userId != myUserId) {
          final next = Set<String>.from(typingUserIds)..add(userId);
          typingUserIds
            ..clear()
            ..addAll(next);
        }
      } else if (event == 'typing:stop') {
        final conversationId = payload['conversationId']?.toString() ?? '';
        final userId = payload['userId']?.toString() ?? '';
        if (conversationId == conversation.id && userId.isNotEmpty) {
          final next = Set<String>.from(typingUserIds)..remove(userId);
          typingUserIds
            ..clear()
            ..addAll(next);
        }
      }
    });
  }

  void onComposerChanged(String value) {
    _socket.emitWithAck(
      'typing:start',
      payload: {'conversationId': conversation.id},
      timeout: const Duration(seconds: 2),
    );
    _typingDebounce?.cancel();
    _typingDebounce = Timer(const Duration(milliseconds: 900), () {
      _socket.emitWithAck(
        'typing:stop',
        payload: {'conversationId': conversation.id},
        timeout: const Duration(seconds: 2),
      );
    });
  }

  String get typingLabel {
    if (typingUserIds.isEmpty) return '';
    final names = conversation.members
        .where((m) => typingUserIds.contains(m.id))
        .map((m) => m.firstName)
        .where((n) => n.trim().isNotEmpty)
        .toList();
    if (names.isEmpty) return 'Typing...';
    if (names.length == 1) return '${names.first} is typing...';
    return '${names.join(", ")} are typing...';
  }

  Future<void> sendText() async {
    final text = textController.text.trim();
    if (text.isEmpty || isSending.value) return;
    textController.clear();
    await _sendPayload({'kind': 'text', 'text': text});
  }

  Future<void> sendFromCamera() async {
    final file = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (file == null) return;
    await _sendMediaFile(File(file.path), kind: 'image');
  }

  Future<void> sendFromGallery() async {
    final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file == null) return;
    await _sendMediaFile(File(file.path), kind: 'image');
  }

  Future<void> sendDocument() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.any,
    );
    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null || path.isEmpty) return;
    await _sendMediaFile(File(path), kind: 'document');
  }

  Future<void> sendAudioFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.audio,
    );
    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null || path.isEmpty) return;
    await _sendMediaFile(File(path), kind: 'audio');
  }

  Future<void> sendVideoFile() async {
    final file = await _picker.pickVideo(source: ImageSource.gallery);
    if (file == null) return;
    await _sendMediaFile(File(file.path), kind: 'video');
  }

  Future<void> sendLocation() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      Get.snackbar('Location', 'Please enable location services.');
      return;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      Get.snackbar('Location', 'Location permission denied.');
      return;
    }

    final pos = await Geolocator.getCurrentPosition();
    await _sendPayload({
      'kind': 'location',
      'location': {
        'latitude': pos.latitude,
        'longitude': pos.longitude,
        'label': 'Shared current location',
      },
    });
  }

  Future<void> sendContact() async {
    final granted = await FlutterContacts.requestPermission(readonly: true);
    if (!granted) {
      Get.snackbar('Contacts', 'Contacts permission denied.');
      return;
    }
    final all = await FlutterContacts.getContacts(withProperties: true);
    if (all.isEmpty) return;
    final contact = all.firstWhereOrNull((c) => c.phones.isNotEmpty);
    if (contact == null) {
      Get.snackbar('Contacts', 'No contact with phone number found.');
      return;
    }
    await _sendPayload({
      'kind': 'contact',
      'sharedContact': {
        'name': contact.displayName,
        'phoneNumber': contact.phones.first.number,
      },
    });
  }

  Future<void> sendPoll({
    required String question,
    required List<String> options,
    bool multipleChoice = false,
  }) async {
    final cleanOptions = options
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (question.trim().isEmpty || cleanOptions.length < 2) return;

    await _sendPayload({
      'kind': 'poll',
      'poll': {
        'question': question.trim(),
        'multipleChoice': multipleChoice,
        'options': cleanOptions
            .asMap()
            .entries
            .map((e) => {'id': 'opt_${e.key + 1}', 'text': e.value})
            .toList(),
      },
    });
  }

  Future<void> sendEvent({
    required String title,
    required DateTime startAt,
    String? notes,
    String? locationLabel,
  }) async {
    if (title.trim().isEmpty) return;
    await _sendPayload({
      'kind': 'event',
      'event': {
        'title': title.trim(),
        'startAt': startAt.toIso8601String(),
        'notes': notes,
        'locationLabel': locationLabel,
      },
    });
  }

  Future<void> voteOnPoll({
    required String messageId,
    required List<String> optionIds,
  }) async {
    final ack = await _socket.emitWithAck(
      'poll:vote',
      payload: {'messageId': messageId, 'optionIds': optionIds},
    );
    if (ack['success'] != true) {
      Get.snackbar('Poll', ack['message']?.toString() ?? 'Failed to vote');
    }
  }

  Future<void> _sendMediaFile(
    File localFile, {
    required String kind,
  }) async {
    isSending.value = true;
    try {
      final upload = await _cloudinary.uploadAnyFile(filePath: localFile.path);
      if (upload == null) {
        Get.snackbar('Upload', 'Failed to upload file');
        return;
      }
      await _sendPayload({
        'kind': kind,
        'file': {
          'url': upload['url'],
          'publicId': upload['public_id'],
          'fileName': localFile.path.split('/').last,
          'mimeType': _mimeFromKind(kind),
          'sizeBytes': await localFile.length(),
        },
      });
    } finally {
      isSending.value = false;
    }
  }

  String _mimeFromKind(String kind) {
    switch (kind) {
      case 'image':
        return 'image/jpeg';
      case 'video':
        return 'video/mp4';
      case 'audio':
        return 'audio/mpeg';
      case 'document':
        return 'application/octet-stream';
      default:
        return 'application/octet-stream';
    }
  }

  Future<void> _sendPayload(Map<String, dynamic> payload) async {
    isSending.value = true;
    try {
      await _socket.connect();
      final ack = await _socket.emitWithAck(
        'message:send',
        payload: {'conversationId': conversation.id, ...payload},
      );
      if (ack['success'] == true) {
        final msgRaw = ack['message'];
        if (msgRaw is Map) {
          final msg = ChatMessageModel.fromJson(
            Map<String, dynamic>.from(msgRaw),
          );
          messages.removeWhere((m) => m.id == msg.id);
          messages.add(msg);
        }
      } else {
        Get.snackbar('Message', ack['message']?.toString() ?? 'Send failed');
      }
    } finally {
      isSending.value = false;
    }
  }

  @override
  void onClose() {
    _socketSub?.cancel();
    _typingDebounce?.cancel();
    textController.dispose();
    super.onClose();
  }
}

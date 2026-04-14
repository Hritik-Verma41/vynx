import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vynx/models/chat_message_model.dart';
import 'package:vynx/pages/chats/chat_thread_controller.dart';
import 'package:vynx/routes/app_routes.dart';

class ChatThreadPage extends StatelessWidget {
  const ChatThreadPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<ChatThreadController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Obx(
          () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                ctrl.conversation.type == 'group'
                    ? (ctrl.conversation.name ?? 'Group Chat')
                    : _peerName(ctrl),
              ),
              if (ctrl.typingLabel.isNotEmpty)
                Text(
                  ctrl.typingLabel,
                  style: const TextStyle(fontSize: 12, color: Colors.greenAccent),
                ),
            ],
          ),
        ),
        actions: [
          if (ctrl.conversation.type == 'group')
            IconButton(
              icon: const Icon(Icons.info_outline_rounded),
              onPressed: () => Get.toNamed(
                Routes.groupInfo,
                arguments: ctrl.conversation,
              ),
            ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _showComposerActions(ctrl),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF1A0B2E), const Color(0xFF09040F)]
                : [const Color(0xFFF3E5F5), Colors.white],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Obx(() {
                if (ctrl.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (ctrl.messages.isEmpty) {
                  return Center(
                    child: Text(
                      'No messages yet',
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: ctrl.messages.length,
                  itemBuilder: (_, index) => _bubble(ctrl.messages[index], ctrl),
                );
              }),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => _showComposerActions(ctrl),
                    ),
                    Expanded(
                      child: TextField(
                        controller: ctrl.textController,
                        minLines: 1,
                        maxLines: 5,
                        onChanged: ctrl.onComposerChanged,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black),
                        decoration: InputDecoration(
                          hintText: 'Type a message',
                          isDense: true,
                          filled: true,
                          fillColor: isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.black.withValues(alpha: 0.04),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Obx(
                      () => IconButton(
                        onPressed: ctrl.isSending.value ? null : ctrl.sendText,
                        icon: ctrl.isSending.value
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.send_rounded),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _peerName(ChatThreadController ctrl) {
    final myId = ctrl.myUserId;
    final peer = ctrl.conversation.members.firstWhereOrNull((m) => m.id != myId);
    return peer?.fullName.isNotEmpty == true ? peer!.fullName : 'Chat';
  }

  Widget _bubble(ChatMessageModel m, ChatThreadController ctrl) {
    final me = m.senderId == ctrl.myUserId;
    final bg = me ? Colors.purple.shade600 : Colors.grey.shade800;
    return Align(
      alignment: me ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: _messageContent(m, ctrl),
      ),
    );
  }

  Widget _messageContent(ChatMessageModel m, ChatThreadController ctrl) {
    switch (m.kind) {
      case 'text':
        return Text(m.text ?? '', style: const TextStyle(color: Colors.white));
      case 'location':
        final loc = m.location;
        return InkWell(
          onTap: () => _openMapLocation(loc),
          child: Text(
            '📍 ${loc?.label ?? 'Shared location'}\n${loc?.latitude}, ${loc?.longitude}',
            style: const TextStyle(color: Colors.white),
          ),
        );
      case 'contact':
        final c = m.sharedContact;
        return Text(
          '👤 ${c?.name ?? ''}\n${c?.phoneNumber ?? ''}',
          style: const TextStyle(color: Colors.white),
        );
      case 'poll':
        final poll = m.poll;
        final opts = poll?.options ?? const [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📊 ${poll?.question ?? 'Poll'}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            ...opts.map(
              (o) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: OutlinedButton(
                  onPressed: () => ctrl.voteOnPoll(messageId: m.id, optionIds: [o.id]),
                  child: Text(o.text),
                ),
              ),
            ),
          ],
        );
      case 'event':
        final e = m.event;
        return Text(
          '📅 ${e?.title ?? 'Event'}\n${e?.startAt?.toLocal()}\n${e?.locationLabel ?? ''}',
          style: const TextStyle(color: Colors.white),
        );
      case 'image':
        return m.file?.url != null
            ? InkWell(
                onTap: () {
                  Get.toNamed(
                    Routes.profileImageViewer,
                    arguments: {
                      'title': 'Photo',
                      'type': 'network',
                      'value': m.file!.url,
                    },
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(m.file!.url, fit: BoxFit.cover),
                ),
              )
            : const Text('📷 Image', style: TextStyle(color: Colors.white));
      case 'video':
      case 'audio':
      case 'document':
      case 'file':
      default:
        return InkWell(
          onTap: () => _openFileUrl(m.file?.url),
          child: Text(
            '📎 ${m.file?.fileName ?? m.kind.toUpperCase()}',
            style: const TextStyle(color: Colors.white),
          ),
        );
    }
  }

  Future<void> _openFileUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openMapLocation(ChatLocationModel? location) async {
    if (location == null) return;
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${location.latitude},${location.longitude}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _showComposerActions(ChatThreadController ctrl) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Get.isDarkMode ? const Color(0xFF1A0B2E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _action('Camera', Icons.camera_alt_rounded, ctrl.sendFromCamera),
            _action('Photo', Icons.photo_rounded, ctrl.sendFromGallery),
            _action('Video', Icons.videocam_rounded, ctrl.sendVideoFile),
            _action('Audio', Icons.audio_file_rounded, ctrl.sendAudioFile),
            _action('Document', Icons.description_rounded, ctrl.sendDocument),
            _action('Location', Icons.location_on_rounded, ctrl.sendLocation),
            _action('Contact', Icons.contact_phone_rounded, ctrl.sendContact),
            _action('Poll', Icons.poll_rounded, () async {
              await _showQuickPollDialog(ctrl);
            }),
            _action('Event', Icons.event_rounded, () async {
              await _showQuickEventDialog(ctrl);
            }),
          ],
        ),
      ),
    );
  }

  Widget _action(String title, IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: 110,
      child: ElevatedButton.icon(
        onPressed: () {
          Get.back();
          onTap();
        },
        icon: Icon(icon, size: 18),
        label: Text(title),
      ),
    );
  }

  Future<void> _showQuickPollDialog(ChatThreadController ctrl) async {
    final qCtrl = TextEditingController();
    final o1 = TextEditingController();
    final o2 = TextEditingController();
    await Get.dialog(
      AlertDialog(
        title: const Text('Create Poll'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: qCtrl, decoration: const InputDecoration(hintText: 'Question')),
            TextField(controller: o1, decoration: const InputDecoration(hintText: 'Option 1')),
            TextField(controller: o2, decoration: const InputDecoration(hintText: 'Option 2')),
          ],
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              ctrl.sendPoll(question: qCtrl.text, options: [o1.text, o2.text]);
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  Future<void> _showQuickEventDialog(ChatThreadController ctrl) async {
    final tCtrl = TextEditingController();
    final lCtrl = TextEditingController();
    await Get.dialog(
      AlertDialog(
        title: const Text('Create Event'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: tCtrl, decoration: const InputDecoration(hintText: 'Event title')),
            TextField(controller: lCtrl, decoration: const InputDecoration(hintText: 'Location (optional)')),
          ],
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              ctrl.sendEvent(
                title: tCtrl.text,
                startAt: DateTime.now().add(const Duration(hours: 1)),
                locationLabel: lCtrl.text.trim().isEmpty ? null : lCtrl.text.trim(),
              );
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}

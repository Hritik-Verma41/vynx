import 'contact_model.dart';

class ConversationPreviewModel {
  final String id;
  final String type;
  final String? name;
  final String? avatar;
  final List<ContactUserModel> members;
  final String? lastMessage;
  final String? lastMessageType;
  final DateTime? lastMessageAt;
  final int unreadCount;

  ConversationPreviewModel({
    required this.id,
    required this.type,
    this.name,
    this.avatar,
    required this.members,
    this.lastMessage,
    this.lastMessageType,
    this.lastMessageAt,
    this.unreadCount = 0,
  });

  factory ConversationPreviewModel.fromJson(Map<String, dynamic> json) {
    final rawMembers = (json['members'] as List?) ?? const [];
    return ConversationPreviewModel(
      id: json['_id'] ?? json['id'] ?? '',
      type: json['type']?.toString() ?? 'direct',
      name: json['name']?.toString(),
      avatar: json['avatar']?.toString(),
      members: rawMembers
          .map((e) => ContactUserModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      lastMessage: json['lastMessage'],
      lastMessageType: json['lastMessageType'],
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.tryParse(json['lastMessageAt'])
          : null,
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
    );
  }
}

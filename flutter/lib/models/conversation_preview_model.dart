import 'contact_model.dart';

class ConversationPreviewModel {
  final String id;
  final List<ContactUserModel> members;
  final String? lastMessage;
  final String? lastMessageType;
  final DateTime? lastMessageAt;

  ConversationPreviewModel({
    required this.id,
    required this.members,
    this.lastMessage,
    this.lastMessageType,
    this.lastMessageAt,
  });

  factory ConversationPreviewModel.fromJson(Map<String, dynamic> json) {
    final rawMembers = (json['members'] as List?) ?? const [];
    return ConversationPreviewModel(
      id: json['_id'] ?? json['id'] ?? '',
      members: rawMembers
          .map((e) => ContactUserModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      lastMessage: json['lastMessage'],
      lastMessageType: json['lastMessageType'],
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.tryParse(json['lastMessageAt'])
          : null,
    );
  }
}

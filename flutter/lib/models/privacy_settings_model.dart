class PrivacySettingsModel {
  final String? id;
  final String user;
  final String lastSeen;
  final String online;
  final String profilePicture;
  final String status;
  final bool readReceipts;
  final DateTime updatedAt;

  PrivacySettingsModel({
    this.id,
    required this.user,
    this.lastSeen = 'everyone',
    this.online = 'everyone',
    this.profilePicture = 'everyone',
    this.status = 'everyone',
    this.readReceipts = true,
    required this.updatedAt,
  });

  factory PrivacySettingsModel.fromJson(Map<String, dynamic> json) =>
      PrivacySettingsModel(
        id: json['_id'],
        user: json['user'] ?? '',
        lastSeen: json['lastSeen'] ?? 'everyone',
        online: json['online'] ?? 'everyone',
        profilePicture: json['profilePicture'] ?? 'everyone',
        status: json['status'] ?? 'everyone',
        readReceipts: json['readReceipts'] ?? true,
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'])
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
    'lastSeen': lastSeen,
    'online': online,
    'profilePicture': profilePicture,
    'status': status,
    'readReceipts': readReceipts,
    'updatedAt': updatedAt.toIso8601String(),
  };
}

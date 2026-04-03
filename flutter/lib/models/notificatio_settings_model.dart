class NotificationSettingsModel {
  final String? id;
  final String user;
  final bool enabled;
  final bool messagePreview;
  final bool sound;
  final bool vibrate;
  final bool calls;
  final DateTime updatedAt;

  NotificationSettingsModel({
    this.id,
    required this.user,
    this.enabled = true,
    this.messagePreview = true,
    this.sound = true,
    this.vibrate = true,
    this.calls = true,
    required this.updatedAt,
  });

  factory NotificationSettingsModel.fromJson(Map<String, dynamic> json) {
    return NotificationSettingsModel(
      id: json['_id'],
      user: json['user'] ?? '',
      enabled: json['enabled'] ?? true,
      messagePreview: json['messagePreview'] ?? true,
      sound: json['sound'] ?? true,
      vibrate: json['vibrate'] ?? true,
      calls: json['calls'] ?? true,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }
  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'messagePreview': messagePreview,
    'sound': sound,
    'vibrate': vibrate,
    'calls': calls,
    'updatedAt': updatedAt.toIso8601String(),
  };

  NotificationSettingsModel copyWith({
    bool? enabled,
    bool? messagePreview,
    bool? sound,
    bool? vibrate,
    bool? calls,
    DateTime? updatedAt,
  }) {
    return NotificationSettingsModel(
      id: id,
      user: user,
      enabled: enabled ?? this.enabled,
      messagePreview: messagePreview ?? this.messagePreview,
      sound: sound ?? this.sound,
      vibrate: vibrate ?? this.vibrate,
      calls: calls ?? this.calls,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

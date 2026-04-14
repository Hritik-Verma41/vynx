class ChatFileModel {
  final String url;
  final String? publicId;
  final String fileName;
  final String mimeType;
  final int sizeBytes;

  ChatFileModel({
    required this.url,
    required this.publicId,
    required this.fileName,
    required this.mimeType,
    required this.sizeBytes,
  });

  factory ChatFileModel.fromJson(Map<String, dynamic> json) {
    return ChatFileModel(
      url: json['url']?.toString() ?? '',
      publicId: json['publicId']?.toString(),
      fileName: json['fileName']?.toString() ?? 'file',
      mimeType: json['mimeType']?.toString() ?? 'application/octet-stream',
      sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'url': url,
    'publicId': publicId,
    'fileName': fileName,
    'mimeType': mimeType,
    'sizeBytes': sizeBytes,
  };
}

class ChatLocationModel {
  final double latitude;
  final double longitude;
  final String? label;

  ChatLocationModel({
    required this.latitude,
    required this.longitude,
    this.label,
  });

  factory ChatLocationModel.fromJson(Map<String, dynamic> json) {
    return ChatLocationModel(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      label: json['label']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'label': label,
  };
}

class ChatSharedContactModel {
  final String name;
  final String phoneNumber;

  ChatSharedContactModel({required this.name, required this.phoneNumber});

  factory ChatSharedContactModel.fromJson(Map<String, dynamic> json) {
    return ChatSharedContactModel(
      name: json['name']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'phoneNumber': phoneNumber,
  };
}

class ChatPollOptionModel {
  final String id;
  final String text;

  ChatPollOptionModel({required this.id, required this.text});

  factory ChatPollOptionModel.fromJson(Map<String, dynamic> json) {
    return ChatPollOptionModel(
      id: json['id']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'text': text};
}

class ChatPollVoteModel {
  final String userId;
  final String optionId;
  final DateTime? votedAt;

  ChatPollVoteModel({
    required this.userId,
    required this.optionId,
    this.votedAt,
  });

  factory ChatPollVoteModel.fromJson(Map<String, dynamic> json) {
    return ChatPollVoteModel(
      userId: json['userId']?.toString() ?? '',
      optionId: json['optionId']?.toString() ?? '',
      votedAt: json['votedAt'] != null
          ? DateTime.tryParse(json['votedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'optionId': optionId,
    'votedAt': votedAt?.toIso8601String(),
  };
}

class ChatPollModel {
  final String question;
  final bool multipleChoice;
  final DateTime? closesAt;
  final List<ChatPollOptionModel> options;
  final List<ChatPollVoteModel> votes;

  ChatPollModel({
    required this.question,
    required this.multipleChoice,
    this.closesAt,
    required this.options,
    required this.votes,
  });

  factory ChatPollModel.fromJson(Map<String, dynamic> json) {
    final optionsRaw = (json['options'] as List?) ?? const [];
    final votesRaw = (json['votes'] as List?) ?? const [];
    return ChatPollModel(
      question: json['question']?.toString() ?? '',
      multipleChoice: json['multipleChoice'] == true,
      closesAt: json['closesAt'] != null
          ? DateTime.tryParse(json['closesAt'].toString())
          : null,
      options: optionsRaw
          .map((e) => ChatPollOptionModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      votes: votesRaw
          .map((e) => ChatPollVoteModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'question': question,
    'multipleChoice': multipleChoice,
    'closesAt': closesAt?.toIso8601String(),
    'options': options.map((e) => e.toJson()).toList(),
    'votes': votes.map((e) => e.toJson()).toList(),
  };
}

class ChatEventModel {
  final String title;
  final String? notes;
  final DateTime? startAt;
  final DateTime? endAt;
  final String? locationLabel;

  ChatEventModel({
    required this.title,
    this.notes,
    this.startAt,
    this.endAt,
    this.locationLabel,
  });

  factory ChatEventModel.fromJson(Map<String, dynamic> json) {
    return ChatEventModel(
      title: json['title']?.toString() ?? '',
      notes: json['notes']?.toString(),
      startAt: json['startAt'] != null
          ? DateTime.tryParse(json['startAt'].toString())
          : null,
      endAt: json['endAt'] != null
          ? DateTime.tryParse(json['endAt'].toString())
          : null,
      locationLabel: json['locationLabel']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'notes': notes,
    'startAt': startAt?.toIso8601String(),
    'endAt': endAt?.toIso8601String(),
    'locationLabel': locationLabel,
  };
}

class ChatMessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String? recipientId;
  final List<String> recipients;
  final String kind;
  final String? text;
  final ChatFileModel? file;
  final ChatLocationModel? location;
  final ChatSharedContactModel? sharedContact;
  final ChatPollModel? poll;
  final ChatEventModel? event;
  final List<String> deliveredTo;
  final List<String> readBy;
  final List<String> downloadedBy;
  final DateTime? createdAt;

  ChatMessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.recipientId,
    required this.recipients,
    required this.kind,
    required this.text,
    required this.file,
    required this.location,
    required this.sharedContact,
    required this.poll,
    required this.event,
    required this.deliveredTo,
    required this.readBy,
    required this.downloadedBy,
    required this.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      conversationId: json['conversation']?.toString() ?? '',
      senderId: json['sender'] is Map
          ? json['sender']['_id']?.toString() ?? ''
          : json['sender']?.toString() ?? '',
      recipientId: json['recipient']?.toString(),
      recipients: ((json['recipients'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      kind: json['kind']?.toString() ?? 'text',
      text: json['text']?.toString(),
      file: json['file'] != null
          ? ChatFileModel.fromJson(Map<String, dynamic>.from(json['file']))
          : null,
      location: json['location'] != null
          ? ChatLocationModel.fromJson(Map<String, dynamic>.from(json['location']))
          : null,
      sharedContact: json['sharedContact'] != null
          ? ChatSharedContactModel.fromJson(
              Map<String, dynamic>.from(json['sharedContact']),
            )
          : null,
      poll: json['poll'] != null
          ? ChatPollModel.fromJson(Map<String, dynamic>.from(json['poll']))
          : null,
      event: json['event'] != null
          ? ChatEventModel.fromJson(Map<String, dynamic>.from(json['event']))
          : null,
      deliveredTo: ((json['deliveredTo'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      readBy: ((json['readBy'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      downloadedBy: ((json['downloadedBy'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}

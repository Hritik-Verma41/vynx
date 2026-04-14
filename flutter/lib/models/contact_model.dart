class ContactUserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final String? profileImage;
  final String status;

  ContactUserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    this.profileImage,
    required this.status,
  });

  factory ContactUserModel.fromJson(Map<String, dynamic> json) {
    return ContactUserModel(
      id: json['_id'] ?? json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      phoneNumber: json['phoneNumber'],
      profileImage: json['profileImage'],
      status: json['status'] ?? 'Available',
    );
  }

  String get fullName => "$firstName $lastName".trim();
}

class ContactModel {
  final String id;
  final String source;
  final bool isBlocked;
  final String relationStatus;
  final String? alias;
  final ContactUserModel contactUser;

  ContactModel({
    required this.id,
    required this.source,
    required this.isBlocked,
    required this.relationStatus,
    this.alias,
    required this.contactUser,
  });

  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      id: json['_id'] ?? json['id'] ?? '',
      source: json['source'] ?? 'phone',
      isBlocked: json['isBlocked'] ?? false,
      relationStatus: json['relationStatus'] ?? 'accepted',
      alias: json['alias'],
      contactUser: ContactUserModel.fromJson(
        Map<String, dynamic>.from(json['contactUser'] ?? {}),
      ),
    );
  }

  bool get isAccepted => relationStatus == 'accepted';
  bool get isIncomingPending => relationStatus == 'pending_incoming';
  bool get isOutgoingPending => relationStatus == 'pending_outgoing';
}

class PhonebookMatchModel {
  final ContactUserModel user;
  final String relationStatus; // none, pending_incoming, pending_outgoing, accepted, rejected
  final String? contactId;

  PhonebookMatchModel({
    required this.user,
    required this.relationStatus,
    this.contactId,
  });

  factory PhonebookMatchModel.fromJson(Map<String, dynamic> json) {
    return PhonebookMatchModel(
      user: ContactUserModel.fromJson(
        Map<String, dynamic>.from(json['user'] ?? {}),
      ),
      relationStatus: json['relationStatus']?.toString() ?? 'none',
      contactId: json['contactId']?.toString(),
    );
  }
}

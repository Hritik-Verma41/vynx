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
  final String? alias;
  final ContactUserModel contactUser;

  ContactModel({
    required this.id,
    required this.source,
    required this.isBlocked,
    this.alias,
    required this.contactUser,
  });

  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      id: json['_id'] ?? json['id'] ?? '',
      source: json['source'] ?? 'phone',
      isBlocked: json['isBlocked'] ?? false,
      alias: json['alias'],
      contactUser: ContactUserModel.fromJson(
        Map<String, dynamic>.from(json['contactUser'] ?? {}),
      ),
    );
  }
}

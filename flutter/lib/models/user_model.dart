class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? profileImage;
  final String status;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.profileImage,
    this.status = 'Available',
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['_id'] ?? json['id'] ?? '',
    firstName: json['firstName'] ?? '',
    lastName: json['lastName'] ?? '',
    email: json['email'] ?? '',
    profileImage: json['profileImage'],
    status: json['status'] ?? "Available",
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
    'profileImage': profileImage,
    'status': status,
  };

  String get fullName => "$firstName $lastName".trim();
}

class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phoneNumber;
  final String? gender;
  final String? profileImage;
  final String status;
  final List<String> providers;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phoneNumber,
    this.gender,
    this.profileImage,
    this.status = 'Available',
    this.providers = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['_id'] ?? json['id'] ?? '',
    firstName: json['firstName'] ?? '',
    lastName: json['lastName'] ?? '',
    email: json['email'] ?? '',
    phoneNumber: json['phoneNumber'],
    gender: json['gender'],
    profileImage: json['profileImage'],
    status: json['status'] ?? "Available",
    providers: json['providers'] != null
        ? List<String>.from(json['providers'])
        : [],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
    'phoneNumber': phoneNumber,
    'gender': gender,
    'profileImage': profileImage,
    'status': status,
    'providers': providers,
  };

  String get fullName => "$firstName $lastName".trim();
}

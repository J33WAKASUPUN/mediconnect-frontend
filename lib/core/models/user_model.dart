import 'package:mediconnect/core/models/profile_models.dart';

class User {
  final String id;
  final String username;
  final String role;
  final String? profilePicture;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String gender;
  final String address;
  final String createdAt;
  final DoctorProfile? doctorProfile;

  User({
    required this.id,
    required this.username,
    required this.role,
    this.profilePicture,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.gender,
    required this.address,
    required this.createdAt,
    this.doctorProfile,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? '',
      username: json['username'] ?? '',
      role: json['role'] ?? '',
      profilePicture: json['profilePicture'],
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      gender: json['gender'] ?? '',
      address: json['address'] ?? '',
      createdAt: json['createdAt'] ?? '',
      doctorProfile: json['doctorProfile'] != null 
          ? DoctorProfile.fromJson(json['doctorProfile'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'username': username,
      'role': role,
      'profilePicture': profilePicture,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phoneNumber': phoneNumber,
      'gender': gender,
      'address': address,
      'createdAt': createdAt,
      'doctorProfile': doctorProfile?.toJson(),
    };
  }

  String? get specialization => doctorProfile?.specialization;
  int? get yearsOfExperience => doctorProfile?.yearsOfExperience;

  User copyWith({
    String? id,
    String? username,
    String? role,
    String? profilePicture,
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    String? gender,
    String? address,
    String? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      role: role ?? this.role,
      profilePicture: profilePicture ?? this.profilePicture,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      gender: gender ?? this.gender,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
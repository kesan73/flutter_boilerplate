// lib/domain/entities/user.dart - 수정된 버전
import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String email;
  final String name;
  final String? profileImageUrl;
  final String? phoneNumber;
  final DateTime? birthdate;
  final String? gender;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  const User({
    required this.id,
    required this.email,
    required this.name,
    this.profileImageUrl,
    this.phoneNumber,
    this.birthdate,
    this.gender,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [
        id,
        email,
        name,
        profileImageUrl,
        phoneNumber,
        birthdate,
        gender,
        createdAt,
        updatedAt,
        isActive,
      ];

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? profileImageUrl,
    String? phoneNumber,
    DateTime? birthdate,
    String? gender,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      birthdate: birthdate ?? this.birthdate,
      gender: gender ?? this.gender,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  // JSON 직렬화
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'profileImageUrl': profileImageUrl,
      'phoneNumber': phoneNumber,
      'birthdate': birthdate?.toIso8601String(),
      'gender': gender,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  // JSON 역직렬화
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      birthdate: json['birthdate'] != null
          ? DateTime.parse(json['birthdate'] as String)
          : null,
      gender: json['gender'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  // toString 메서드 (디버깅용)
  @override
  String toString() {
    return 'User(id: $id, email: $email, name: $name, '
        'profileImageUrl: $profileImageUrl, phoneNumber: $phoneNumber, '
        'birthdate: $birthdate, gender: $gender, '
        'createdAt: $createdAt, updatedAt: $updatedAt, isActive: $isActive)';
  }
}

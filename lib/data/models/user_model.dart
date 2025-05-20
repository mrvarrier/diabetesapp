// File: lib/data/models/user_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/constants.dart';

class User {
  final String id;
  final String name;
  final String email;
  final int age;
  final String gender;
  final String diabetesType;
  final String treatmentMethod;
  final String? profileImageUrl;
  final int totalPoints;
  final int currentStreak;
  final int longestStreak;
  final String userType;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final bool isOnboardingCompleted;
  final Map<String, dynamic>? additionalInfo;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.age,
    required this.gender,
    required this.diabetesType,
    required this.treatmentMethod,
    this.profileImageUrl,
    this.totalPoints = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.userType = AppConstants.userTypePatient,
    required this.createdAt,
    required this.lastLoginAt,
    this.isOnboardingCompleted = false,
    this.additionalInfo,
  });

  // Convert User model to JSON format for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'age': age,
      'gender': gender,
      'diabetesType': diabetesType,
      'treatmentMethod': treatmentMethod,
      'profileImageUrl': profileImageUrl,
      'totalPoints': totalPoints,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'userType': userType,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': Timestamp.fromDate(lastLoginAt),
      'isOnboardingCompleted': isOnboardingCompleted,
      'additionalInfo': additionalInfo,
    };
  }

  // Create User model from Firestore document
  factory User.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return User(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      age: data['age'] ?? 0,
      gender: data['gender'] ?? '',
      diabetesType: data['diabetesType'] ?? AppConstants.diabetesType2,
      treatmentMethod: data['treatmentMethod'] ?? AppConstants.treatmentLifestyle,
      profileImageUrl: data['profileImageUrl'],
      totalPoints: data['totalPoints'] ?? 0,
      currentStreak: data['currentStreak'] ?? 0,
      longestStreak: data['longestStreak'] ?? 0,
      userType: data['userType'] ?? AppConstants.userTypePatient,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp).toDate(),
      isOnboardingCompleted: data['isOnboardingCompleted'] ?? false,
      additionalInfo: data['additionalInfo'],
    );
  }

  // Create User model from Firestore document with specific ID
  factory User.fromJson(Map<String, dynamic> json, String id) {
    return User(
      id: id,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      age: json['age'] ?? 0,
      gender: json['gender'] ?? '',
      diabetesType: json['diabetesType'] ?? AppConstants.diabetesType2,
      treatmentMethod: json['treatmentMethod'] ?? AppConstants.treatmentLifestyle,
      profileImageUrl: json['profileImageUrl'],
      totalPoints: json['totalPoints'] ?? 0,
      currentStreak: json['currentStreak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
      userType: json['userType'] ?? AppConstants.userTypePatient,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      lastLoginAt: (json['lastLoginAt'] as Timestamp).toDate(),
      isOnboardingCompleted: json['isOnboardingCompleted'] ?? false,
      additionalInfo: json['additionalInfo'],
    );
  }

  // Create a copy of User with modified fields
  User copyWith({
    String? id,
    String? name,
    String? email,
    int? age,
    String? gender,
    String? diabetesType,
    String? treatmentMethod,
    String? profileImageUrl,
    int? totalPoints,
    int? currentStreak,
    int? longestStreak,
    String? userType,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isOnboardingCompleted,
    Map<String, dynamic>? additionalInfo,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      diabetesType: diabetesType ?? this.diabetesType,
      treatmentMethod: treatmentMethod ?? this.treatmentMethod,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      totalPoints: totalPoints ?? this.totalPoints,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      userType: userType ?? this.userType,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isOnboardingCompleted: isOnboardingCompleted ?? this.isOnboardingCompleted,
      additionalInfo: additionalInfo ?? this.additionalInfo,
    );
  }

  // Create a User instance for offline use
  factory User.offline({
    required String id,
    required String name,
    required String email,
    required int age,
    required String gender,
    required String diabetesType,
    required String treatmentMethod,
  }) {
    return User(
      id: id,
      name: name,
      email: email,
      age: age,
      gender: gender,
      diabetesType: diabetesType,
      treatmentMethod: treatmentMethod,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );
  }
}
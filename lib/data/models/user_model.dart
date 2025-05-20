import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final int age;
  final String gender;
  final String diabetesType;
  final String treatmentMethod;
  final int points;
  final int streakDays;
  final DateTime lastActive;
  final bool onboardingComplete;
  final List<String> completedLessons;
  final List<String> unlockedAchievements;
  final String assignedPlanId;
  final Map<String, dynamic> notificationSettings;
  final bool isDarkModeEnabled;

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.age,
    required this.gender,
    required this.diabetesType,
    required this.treatmentMethod,
    this.points = 0,
    this.streakDays = 0,
    required this.lastActive,
    this.onboardingComplete = false,
    this.completedLessons = const [],
    this.unlockedAchievements = const [],
    required this.assignedPlanId,
    required this.notificationSettings,
    this.isDarkModeEnabled = false,
  });

  // Create a UserModel object from a Firebase document snapshot
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? '',
      age: data['age'] ?? 0,
      gender: data['gender'] ?? '',
      diabetesType: data['diabetesType'] ?? '',
      treatmentMethod: data['treatmentMethod'] ?? '',
      points: data['points'] ?? 0,
      streakDays: data['streakDays'] ?? 0,
      lastActive: (data['lastActive'] as Timestamp?)?.toDate() ?? DateTime.now(),
      onboardingComplete: data['onboardingComplete'] ?? false,
      completedLessons: List<String>.from(data['completedLessons'] ?? []),
      unlockedAchievements: List<String>.from(data['unlockedAchievements'] ?? []),
      assignedPlanId: data['assignedPlanId'] ?? '',
      notificationSettings: data['notificationSettings'] ?? {'dailyReminder': true, 'achievements': true, 'newContent': true},
      isDarkModeEnabled: data['isDarkModeEnabled'] ?? false,
    );
  }

  // Create a map from a UserModel object
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'fullName': fullName,
      'age': age,
      'gender': gender,
      'diabetesType': diabetesType,
      'treatmentMethod': treatmentMethod,
      'points': points,
      'streakDays': streakDays,
      'lastActive': Timestamp.fromDate(lastActive),
      'onboardingComplete': onboardingComplete,
      'completedLessons': completedLessons,
      'unlockedAchievements': unlockedAchievements,
      'assignedPlanId': assignedPlanId,
      'notificationSettings': notificationSettings,
      'isDarkModeEnabled': isDarkModeEnabled,
    };
  }

  // Create a copy of the UserModel with updated fields
  UserModel copyWith({
    String? uid,
    String? email,
    String? fullName,
    int? age,
    String? gender,
    String? diabetesType,
    String? treatmentMethod,
    int? points,
    int? streakDays,
    DateTime? lastActive,
    bool? onboardingComplete,
    List<String>? completedLessons,
    List<String>? unlockedAchievements,
    String? assignedPlanId,
    Map<String, dynamic>? notificationSettings,
    bool? isDarkModeEnabled,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      diabetesType: diabetesType ?? this.diabetesType,
      treatmentMethod: treatmentMethod ?? this.treatmentMethod,
      points: points ?? this.points,
      streakDays: streakDays ?? this.streakDays,
      lastActive: lastActive ?? this.lastActive,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      completedLessons: completedLessons ?? this.completedLessons,
      unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
      assignedPlanId: assignedPlanId ?? this.assignedPlanId,
      notificationSettings: notificationSettings ?? this.notificationSettings,
      isDarkModeEnabled: isDarkModeEnabled ?? this.isDarkModeEnabled,
    );
  }
}
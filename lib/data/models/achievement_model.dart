import 'package:cloud_firestore/cloud_firestore.dart';

class AchievementModel {
  final String id;
  final String title;
  final String description;
  final String iconPath;
  final int pointsValue;
  final String achievementType; // e.g., streak, completion, quiz, etc.
  final Map<String, dynamic> criteria; // Requirements to unlock this achievement
  final bool isHidden; // Whether this achievement is a surprise

  AchievementModel({
    required this.id,
    required this.title,
    required this.description,
    required this.iconPath,
    required this.pointsValue,
    required this.achievementType,
    required this.criteria,
    this.isHidden = false,
  });

  // Create an AchievementModel object from a Firebase document snapshot
  factory AchievementModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return AchievementModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      iconPath: data['iconPath'] ?? '',
      pointsValue: data['pointsValue'] ?? 0,
      achievementType: data['achievementType'] ?? '',
      criteria: data['criteria'] ?? {},
      isHidden: data['isHidden'] ?? false,
    );
  }

  // Create a map from an AchievementModel object
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'iconPath': iconPath,
      'pointsValue': pointsValue,
      'achievementType': achievementType,
      'criteria': criteria,
      'isHidden': isHidden,
    };
  }

  // Create a copy of the AchievementModel with updated fields
  AchievementModel copyWith({
    String? id,
    String? title,
    String? description,
    String? iconPath,
    int? pointsValue,
    String? achievementType,
    Map<String, dynamic>? criteria,
    bool? isHidden,
  }) {
    return AchievementModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      iconPath: iconPath ?? this.iconPath,
      pointsValue: pointsValue ?? this.pointsValue,
      achievementType: achievementType ?? this.achievementType,
      criteria: criteria ?? this.criteria,
      isHidden: isHidden ?? this.isHidden,
    );
  }
}
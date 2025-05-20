// File: lib/data/models/achievement_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/constants.dart';

class Achievement {
  final String id;
  final String userId;
  final String achievementType;
  final String title;
  final String description;
  final String? iconUrl;
  final int pointsAwarded;
  final DateTime awardedAt;
  final Map<String, dynamic>? metadata;

  Achievement({
    required this.id,
    required this.userId,
    required this.achievementType,
    required this.title,
    required this.description,
    this.iconUrl,
    this.pointsAwarded = 0,
    required this.awardedAt,
    this.metadata,
  });

  // Convert Achievement model to JSON format for Firestore
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'achievementType': achievementType,
      'title': title,
      'description': description,
      'iconUrl': iconUrl,
      'pointsAwarded': pointsAwarded,
      'awardedAt': Timestamp.fromDate(awardedAt),
      'metadata': metadata,
    };
  }

  // Create Achievement model from Firestore document
  factory Achievement.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Achievement(
      id: doc.id,
      userId: data['userId'] ?? '',
      achievementType: data['achievementType'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      iconUrl: data['iconUrl'],
      pointsAwarded: data['pointsAwarded'] ?? 0,
      awardedAt: data['awardedAt'] != null
          ? (data['awardedAt'] as Timestamp).toDate()
          : DateTime.now(),
      metadata: data['metadata'],
    );
  }

  // Create Achievement model from JSON data
  factory Achievement.fromJson(Map<String, dynamic> json, String id) {
    return Achievement(
      id: id,
      userId: json['userId'] ?? '',
      achievementType: json['achievementType'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      iconUrl: json['iconUrl'],
      pointsAwarded: json['pointsAwarded'] ?? 0,
      awardedAt: json['awardedAt'] != null
          ? (json['awardedAt'] as Timestamp).toDate()
          : DateTime.now(),
      metadata: json['metadata'],
    );
  }

  // Create a new Achievement based on the achievement type
  factory Achievement.create({
    required String userId,
    required String achievementType,
  }) {
    String title = '';
    String description = '';
    int pointsAwarded = 0;

    switch (achievementType) {
      case AppConstants.achievementFirstLesson:
        title = 'First Step';
        description = 'Completed your first lesson';
        pointsAwarded = 10;
        break;
      case AppConstants.achievement100Points:
        title = 'Point Collector';
        description = 'Earned 100 points';
        pointsAwarded = 15;
        break;
      case AppConstants.achievement500Points:
        title = 'Knowledge Seeker';
        description = 'Earned 500 points';
        pointsAwarded = 25;
        break;
      case AppConstants.achievement1000Points:
        title = 'Diabetes Scholar';
        description = 'Earned 1000 points';
        pointsAwarded = 50;
        break;
      case AppConstants.achievementPerfectQuiz:
        title = 'Perfect Score';
        description = 'Achieved a perfect score on a quiz';
        pointsAwarded = 20;
        break;
      case AppConstants.achievement3DayStreak:
        title = 'Consistent Learner';
        description = 'Maintained a 3-day learning streak';
        pointsAwarded = 15;
        break;
      case AppConstants.achievement7DayStreak:
        title = 'Weekly Warrior';
        description = 'Maintained a 7-day learning streak';
        pointsAwarded = 30;
        break;
      case AppConstants.achievementCompletePlan:
        title = 'Plan Master';
        description = 'Completed an entire education plan';
        pointsAwarded = 50;
        break;
      default:
        title = 'Achievement Unlocked';
        description = 'You earned a special achievement';
        pointsAwarded = 10;
    }

    return Achievement(
      id: '$userId-$achievementType',
      userId: userId,
      achievementType: achievementType,
      title: title,
      description: description,
      pointsAwarded: pointsAwarded,
      awardedAt: DateTime.now(),
    );
  }

  // Add copyWith method to fix the error
  Achievement copyWith({
    String? id,
    String? userId,
    String? achievementType,
    String? title,
    String? description,
    String? iconUrl,
    int? pointsAwarded,
    DateTime? awardedAt,
    Map<String, dynamic>? metadata,
  }) {
    return Achievement(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      achievementType: achievementType ?? this.achievementType,
      title: title ?? this.title,
      description: description ?? this.description,
      iconUrl: iconUrl ?? this.iconUrl,
      pointsAwarded: pointsAwarded ?? this.pointsAwarded,
      awardedAt: awardedAt ?? this.awardedAt,
      metadata: metadata ?? this.metadata,
    );
  }
}
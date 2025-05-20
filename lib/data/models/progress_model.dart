// File: lib/data/models/progress_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Progress {
  final String id;
  final String userId;
  final String contentId;
  final bool isCompleted;
  final int pointsEarned;
  final double progressPercentage; // 0-100
  final DateTime startedAt;
  final DateTime? completedAt;
  final DateTime lastInteractionAt;
  final Map<String, dynamic>? videoProgress; // For YouTube videos
  final Map<String, dynamic>? quizResults; // Quiz results if applicable

  Progress({
    required this.id,
    required this.userId,
    required this.contentId,
    this.isCompleted = false,
    this.pointsEarned = 0,
    this.progressPercentage = 0.0,
    required this.startedAt,
    this.completedAt,
    required this.lastInteractionAt,
    this.videoProgress,
    this.quizResults,
  });

  // Convert Progress model to JSON format for Firestore
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'contentId': contentId,
      'isCompleted': isCompleted,
      'pointsEarned': pointsEarned,
      'progressPercentage': progressPercentage,
      'startedAt': Timestamp.fromDate(startedAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'lastInteractionAt': Timestamp.fromDate(lastInteractionAt),
      'videoProgress': videoProgress,
      'quizResults': quizResults,
    };
  }

  // Create Progress model from Firestore document
  factory Progress.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Progress(
      id: doc.id,
      userId: data['userId'] ?? '',
      contentId: data['contentId'] ?? '',
      isCompleted: data['isCompleted'] ?? false,
      pointsEarned: data['pointsEarned'] ?? 0,
      progressPercentage: (data['progressPercentage'] ?? 0.0).toDouble(),
      startedAt: data['startedAt'] != null
          ? (data['startedAt'] as Timestamp).toDate()
          : DateTime.now(),
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      lastInteractionAt: data['lastInteractionAt'] != null
          ? (data['lastInteractionAt'] as Timestamp).toDate()
          : DateTime.now(),
      videoProgress: data['videoProgress'],
      quizResults: data['quizResults'],
    );
  }

  // Create Progress model from JSON data
  factory Progress.fromJson(Map<String, dynamic> json, String id) {
    return Progress(
      id: id,
      userId: json['userId'] ?? '',
      contentId: json['contentId'] ?? '',
      isCompleted: json['isCompleted'] ?? false,
      pointsEarned: json['pointsEarned'] ?? 0,
      progressPercentage: (json['progressPercentage'] ?? 0.0).toDouble(),
      startedAt: json['startedAt'] != null
          ? (json['startedAt'] as Timestamp).toDate()
          : DateTime.now(),
      completedAt: json['completedAt'] != null
          ? (json['completedAt'] as Timestamp).toDate()
          : null,
      lastInteractionAt: json['lastInteractionAt'] != null
          ? (json['lastInteractionAt'] as Timestamp).toDate()
          : DateTime.now(),
      videoProgress: json['videoProgress'],
      quizResults: json['quizResults'],
    );
  }

  // Create a copy of Progress with modified fields
  Progress copyWith({
    String? id,
    String? userId,
    String? contentId,
    bool? isCompleted,
    int? pointsEarned,
    double? progressPercentage,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? lastInteractionAt,
    Map<String, dynamic>? videoProgress,
    Map<String, dynamic>? quizResults,
  }) {
    return Progress(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      contentId: contentId ?? this.contentId,
      isCompleted: isCompleted ?? this.isCompleted,
      pointsEarned: pointsEarned ?? this.pointsEarned,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      lastInteractionAt: lastInteractionAt ?? this.lastInteractionAt,
      videoProgress: videoProgress ?? this.videoProgress,
      quizResults: quizResults ?? this.quizResults,
    );
  }

  // Create a new Progress instance for offline storage
  factory Progress.initial({
    required String userId,
    required String contentId,
  }) {
    return Progress(
      id: '$userId-$contentId', // Create a unique ID
      userId: userId,
      contentId: contentId,
      startedAt: DateTime.now(),
      lastInteractionAt: DateTime.now(),
    );
  }

  // Update video progress and calculate overall progress
  Progress updateVideoProgress({
    required int currentPosition,
    required int totalDuration,
    required bool isCompleted,
  }) {
    // Calculate new progress percentage
    final newProgressPercentage = (currentPosition / totalDuration) * 100;

    // Create updated video progress data
    final newVideoProgress = {
      'currentPosition': currentPosition,
      'totalDuration': totalDuration,
      'lastPosition': currentPosition,
      'lastUpdated': DateTime.now().millisecondsSinceEpoch,
    };

    return copyWith(
      progressPercentage: newProgressPercentage,
      isCompleted: isCompleted,
      completedAt: isCompleted ? DateTime.now() : null,
      lastInteractionAt: DateTime.now(),
      videoProgress: newVideoProgress,
    );
  }

  // Update quiz results and progress
  Progress updateQuizResults({
    required int score,
    required int totalPossible,
    required bool isPassed,
    required int pointsEarned,
  }) {
    // Create updated quiz results data
    final newQuizResults = {
      'score': score,
      'totalPossible': totalPossible,
      'percentage': (score / totalPossible) * 100,
      'isPassed': isPassed,
      'completedAt': DateTime.now().millisecondsSinceEpoch,
    };

    return copyWith(
      progressPercentage: isPassed ? 100.0 : (score / totalPossible) * 100,
      isCompleted: isPassed,
      pointsEarned: this.pointsEarned + pointsEarned,
      completedAt: isPassed ? DateTime.now() : null,
      lastInteractionAt: DateTime.now(),
      quizResults: newQuizResults,
    );
  }
}
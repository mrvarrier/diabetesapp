import 'package:cloud_firestore/cloud_firestore.dart';

class ProgressModel {
  final String id;
  final String userId;
  final String contentId;
  final bool isCompleted;
  final int pointsEarned;
  final DateTime startTime;
  final DateTime? completionTime;
  final int watchTimeSeconds; // For tracking video watching time
  final Map<String, dynamic> metadata; // Additional tracking data

  ProgressModel({
    required this.id,
    required this.userId,
    required this.contentId,
    this.isCompleted = false,
    this.pointsEarned = 0,
    required this.startTime,
    this.completionTime,
    this.watchTimeSeconds = 0,
    this.metadata = const {},
  });

  // Create a ProgressModel object from a Firebase document snapshot
  factory ProgressModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return ProgressModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      contentId: data['contentId'] ?? '',
      isCompleted: data['isCompleted'] ?? false,
      pointsEarned: data['pointsEarned'] ?? 0,
      startTime: (data['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completionTime: (data['completionTime'] as Timestamp?)?.toDate(),
      watchTimeSeconds: data['watchTimeSeconds'] ?? 0,
      metadata: data['metadata'] ?? {},
    );
  }

  // Create a map from a ProgressModel object
  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {
      'userId': userId,
      'contentId': contentId,
      'isCompleted': isCompleted,
      'pointsEarned': pointsEarned,
      'startTime': Timestamp.fromDate(startTime),
      'watchTimeSeconds': watchTimeSeconds,
      'metadata': metadata,
    };

    if (completionTime != null) {
      map['completionTime'] = Timestamp.fromDate(completionTime!);
    }

    return map;
  }

  // Calculate duration spent on this content in minutes
  int get durationMinutes {
    if (completionTime != null) {
      return completionTime!.difference(startTime).inMinutes;
    } else {
      return DateTime.now().difference(startTime).inMinutes;
    }
  }

  // Create a copy of the ProgressModel with updated fields
  ProgressModel copyWith({
    String? id,
    String? userId,
    String? contentId,
    bool? isCompleted,
    int? pointsEarned,
    DateTime? startTime,
    DateTime? completionTime,
    int? watchTimeSeconds,
    Map<String, dynamic>? metadata,
  }) {
    return ProgressModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      contentId: contentId ?? this.contentId,
      isCompleted: isCompleted ?? this.isCompleted,
      pointsEarned: pointsEarned ?? this.pointsEarned,
      startTime: startTime ?? this.startTime,
      completionTime: completionTime ?? this.completionTime,
      watchTimeSeconds: watchTimeSeconds ?? this.watchTimeSeconds,
      metadata: metadata ?? this.metadata,
    );
  }
}
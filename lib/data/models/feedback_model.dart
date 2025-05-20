import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackModel {
  final String id;
  final String userId;
  final String contentId;
  final int rating; // 1-5 stars
  final String? comment;
  final DateTime createdAt;
  final Map<String, dynamic> metadata; // Additional data like device, app version

  FeedbackModel({
    required this.id,
    required this.userId,
    required this.contentId,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.metadata = const {},
  });

  // Create a FeedbackModel object from a Firebase document snapshot
  factory FeedbackModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return FeedbackModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      contentId: data['contentId'] ?? '',
      rating: data['rating'] ?? 0,
      comment: data['comment'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: data['metadata'] ?? {},
    );
  }

  // Create a map from a FeedbackModel object
  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {
      'userId': userId,
      'contentId': contentId,
      'rating': rating,
      'createdAt': Timestamp.fromDate(createdAt),
      'metadata': metadata,
    };

    if (comment != null) {
      map['comment'] = comment;
    }

    return map;
  }

  // Create a copy of the FeedbackModel with updated fields
  FeedbackModel copyWith({
    String? id,
    String? userId,
    String? contentId,
    int? rating,
    String? comment,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
  }) {
    return FeedbackModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      contentId: contentId ?? this.contentId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
    );
  }
}
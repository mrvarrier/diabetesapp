import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String notificationType; // e.g., reminder, achievement, content
  final Map<String, dynamic> data; // Additional data for deep linking
  final DateTime createdAt;
  final bool isRead;
  final String? actionRoute; // Navigation route for when notification is tapped

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.notificationType,
    this.data = const {},
    required this.createdAt,
    this.isRead = false,
    this.actionRoute,
  });

  // Create a NotificationModel object from a Firebase document snapshot
  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return NotificationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      notificationType: data['notificationType'] ?? '',
      data: data['data'] ?? {},
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
      actionRoute: data['actionRoute'],
    );
  }

  // Create a map from a NotificationModel object
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'notificationType': notificationType,
      'data': data,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      'actionRoute': actionRoute,
    };
  }

  // Create a copy of the NotificationModel with updated fields
  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    String? notificationType,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    bool? isRead,
    String? actionRoute,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      notificationType: notificationType ?? this.notificationType,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      actionRoute: actionRoute ?? this.actionRoute,
    );
  }
}
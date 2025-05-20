// File: lib/data/models/content_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/constants.dart';

class Content {
  final String id;
  final String title;
  final String description;
  final String contentType; // video, slide
  final int order;
  final String? youtubeVideoId;
  final List<String>? slideUrls;
  final String? thumbnailUrl;
  final int pointsToEarn;
  final Duration? duration;
  final List<String> tags;
  final String? quizId;
  final List<String> requiredDiabetesTypes;
  final List<String> requiredTreatmentMethods;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;
  final bool isActive;

  Content({
    required this.id,
    required this.title,
    required this.description,
    required this.contentType,
    required this.order,
    this.youtubeVideoId,
    this.slideUrls,
    this.thumbnailUrl,
    this.pointsToEarn = AppConstants.defaultPointsPerLesson,
    this.duration,
    this.tags = const [],
    this.quizId,
    this.requiredDiabetesTypes = const [],
    this.requiredTreatmentMethods = const [],
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
    this.isActive = true,
  });

  // Check if this content is applicable to a user with specific diabetes type and treatment method
  bool isApplicableTo(String diabetesType, String treatmentMethod) {
    return (requiredDiabetesTypes.isEmpty || requiredDiabetesTypes.contains(diabetesType)) &&
        (requiredTreatmentMethods.isEmpty || requiredTreatmentMethods.contains(treatmentMethod));
  }

  // Convert Content model to JSON format for Firestore
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'contentType': contentType,
      'order': order,
      'youtubeVideoId': youtubeVideoId,
      'slideUrls': slideUrls,
      'thumbnailUrl': thumbnailUrl,
      'pointsToEarn': pointsToEarn,
      'duration': duration?.inSeconds,
      'tags': tags,
      'quizId': quizId,
      'requiredDiabetesTypes': requiredDiabetesTypes,
      'requiredTreatmentMethods': requiredTreatmentMethods,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'metadata': metadata,
      'isActive': isActive,
    };
  }

  // Create Content model from Firestore document
  factory Content.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Content(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      contentType: data['contentType'] ?? AppConstants.contentTypeVideo,
      order: data['order'] ?? 0,
      youtubeVideoId: data['youtubeVideoId'],
      slideUrls: data['slideUrls'] != null
          ? List<String>.from(data['slideUrls'])
          : null,
      thumbnailUrl: data['thumbnailUrl'],
      pointsToEarn: data['pointsToEarn'] ?? AppConstants.defaultPointsPerLesson,
      duration: data['duration'] != null
          ? Duration(seconds: data['duration'])
          : null,
      tags: data['tags'] != null
          ? List<String>.from(data['tags'])
          : [],
      quizId: data['quizId'],
      requiredDiabetesTypes: data['requiredDiabetesTypes'] != null
          ? List<String>.from(data['requiredDiabetesTypes'])
          : [],
      requiredTreatmentMethods: data['requiredTreatmentMethods'] != null
          ? List<String>.from(data['requiredTreatmentMethods'])
          : [],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      metadata: data['metadata'],
      isActive: data['isActive'] ?? true,
    );
  }

  // Create Content model from JSON data
  factory Content.fromJson(Map<String, dynamic> json, String id) {
    return Content(
      id: id,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      contentType: json['contentType'] ?? AppConstants.contentTypeVideo,
      order: json['order'] ?? 0,
      youtubeVideoId: json['youtubeVideoId'],
      slideUrls: json['slideUrls'] != null
          ? List<String>.from(json['slideUrls'])
          : null,
      thumbnailUrl: json['thumbnailUrl'],
      pointsToEarn: json['pointsToEarn'] ?? AppConstants.defaultPointsPerLesson,
      duration: json['duration'] != null
          ? Duration(seconds: json['duration'])
          : null,
      tags: json['tags'] != null
          ? List<String>.from(json['tags'])
          : [],
      quizId: json['quizId'],
      requiredDiabetesTypes: json['requiredDiabetesTypes'] != null
          ? List<String>.from(json['requiredDiabetesTypes'])
          : [],
      requiredTreatmentMethods: json['requiredTreatmentMethods'] != null
          ? List<String>.from(json['requiredTreatmentMethods'])
          : [],
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      metadata: json['metadata'],
      isActive: json['isActive'] ?? true,
    );
  }

  // Create a copy of Content with modified fields
  Content copyWith({
    String? id,
    String? title,
    String? description,
    String? contentType,
    int? order,
    String? youtubeVideoId,
    List<String>? slideUrls,
    String? thumbnailUrl,
    int? pointsToEarn,
    Duration? duration,
    List<String>? tags,
    String? quizId,
    List<String>? requiredDiabetesTypes,
    List<String>? requiredTreatmentMethods,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
    bool? isActive,
  }) {
    return Content(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      contentType: contentType ?? this.contentType,
      order: order ?? this.order,
      youtubeVideoId: youtubeVideoId ?? this.youtubeVideoId,
      slideUrls: slideUrls ?? this.slideUrls,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      pointsToEarn: pointsToEarn ?? this.pointsToEarn,
      duration: duration ?? this.duration,
      tags: tags ?? this.tags,
      quizId: quizId ?? this.quizId,
      requiredDiabetesTypes: requiredDiabetesTypes ?? this.requiredDiabetesTypes,
      requiredTreatmentMethods: requiredTreatmentMethods ?? this.requiredTreatmentMethods,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
      isActive: isActive ?? this.isActive,
    );
  }
}
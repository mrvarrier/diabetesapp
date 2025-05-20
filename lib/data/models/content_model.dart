import 'package:cloud_firestore/cloud_firestore.dart';

enum ContentType {
  video,
  slides,
  mixed
}

class ContentModel {
  final String id;
  final String title;
  final String description;
  final ContentType contentType;
  final String youtubeVideoId;
  final List<String> slideUrls;
  final List<String> slideContents;
  final int pointsValue;
  final String moduleId;
  final int sequenceNumber;
  final int estimatedDuration; // in minutes
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDownloadable;
  final Map<String, dynamic> metadata;

  ContentModel({
    required this.id,
    required this.title,
    required this.description,
    required this.contentType,
    this.youtubeVideoId = '',
    this.slideUrls = const [],
    this.slideContents = const [],
    required this.pointsValue,
    required this.moduleId,
    required this.sequenceNumber,
    required this.estimatedDuration,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.isDownloadable = true,
    this.metadata = const {},
  });

  // Create a ContentModel object from a Firebase document snapshot
  factory ContentModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return ContentModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      contentType: ContentType.values.firstWhere(
            (e) => e.toString() == 'ContentType.${data['contentType']}',
        orElse: () => ContentType.mixed,
      ),
      youtubeVideoId: data['youtubeVideoId'] ?? '',
      slideUrls: List<String>.from(data['slideUrls'] ?? []),
      slideContents: List<String>.from(data['slideContents'] ?? []),
      pointsValue: data['pointsValue'] ?? 0,
      moduleId: data['moduleId'] ?? '',
      sequenceNumber: data['sequenceNumber'] ?? 0,
      estimatedDuration: data['estimatedDuration'] ?? 0,
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isDownloadable: data['isDownloadable'] ?? true,
      metadata: data['metadata'] ?? {},
    );
  }

  // Create a map from a ContentModel object
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'contentType': contentType.toString().split('.').last,
      'youtubeVideoId': youtubeVideoId,
      'slideUrls': slideUrls,
      'slideContents': slideContents,
      'pointsValue': pointsValue,
      'moduleId': moduleId,
      'sequenceNumber': sequenceNumber,
      'estimatedDuration': estimatedDuration,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isDownloadable': isDownloadable,
      'metadata': metadata,
    };
  }

  // Create a copy of the ContentModel with updated fields
  ContentModel copyWith({
    String? id,
    String? title,
    String? description,
    ContentType? contentType,
    String? youtubeVideoId,
    List<String>? slideUrls,
    List<String>? slideContents,
    int? pointsValue,
    String? moduleId,
    int? sequenceNumber,
    int? estimatedDuration,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDownloadable,
    Map<String, dynamic>? metadata,
  }) {
    return ContentModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      contentType: contentType ?? this.contentType,
      youtubeVideoId: youtubeVideoId ?? this.youtubeVideoId,
      slideUrls: slideUrls ?? this.slideUrls,
      slideContents: slideContents ?? this.slideContents,
      pointsValue: pointsValue ?? this.pointsValue,
      moduleId: moduleId ?? this.moduleId,
      sequenceNumber: sequenceNumber ?? this.sequenceNumber,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDownloadable: isDownloadable ?? this.isDownloadable,
      metadata: metadata ?? this.metadata,
    );
  }

  // Returns true if the content has a valid YouTube video ID
  bool get hasVideo => youtubeVideoId.isNotEmpty;

  // Returns true if the content has slides
  bool get hasSlides => slideUrls.isNotEmpty || slideContents.isNotEmpty;

  // Returns true if this content is part of a sequence
  bool get isSequential => sequenceNumber > 0;
}
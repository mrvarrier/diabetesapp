import 'package:cloud_firestore/cloud_firestore.dart';

class QuizModel {
  final String id;
  final String title;
  final String description;
  final String moduleId;
  final String contentId; // Related content (lesson)
  final int pointsValue;
  final int passingScore; // Percentage needed to pass (e.g., 70)
  final List<QuizQuestion> questions;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  QuizModel({
    required this.id,
    required this.title,
    required this.description,
    required this.moduleId,
    required this.contentId,
    required this.pointsValue,
    this.passingScore = 70,
    required this.questions,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  // Create a QuizModel object from a Firebase document snapshot
  factory QuizModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Parse questions
    List<QuizQuestion> questionsList = [];
    if (data['questions'] != null && data['questions'] is List) {
      questionsList = (data['questions'] as List)
          .map((q) => QuizQuestion.fromMap(q as Map<String, dynamic>))
          .toList();
    }

    return QuizModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      moduleId: data['moduleId'] ?? '',
      contentId: data['contentId'] ?? '',
      pointsValue: data['pointsValue'] ?? 0,
      passingScore: data['passingScore'] ?? 70,
      questions: questionsList,
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Create a map from a QuizModel object
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'moduleId': moduleId,
      'contentId': contentId,
      'pointsValue': pointsValue,
      'passingScore': passingScore,
      'questions': questions.map((q) => q.toMap()).toList(),
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Calculate the total possible score
  int get totalPossiblePoints => questions.length;

  // Create a copy of the QuizModel with updated fields
  QuizModel copyWith({
    String? id,
    String? title,
    String? description,
    String? moduleId,
    String? contentId,
    int? pointsValue,
    int? passingScore,
    List<QuizQuestion>? questions,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return QuizModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      moduleId: moduleId ?? this.moduleId,
      contentId: contentId ?? this.contentId,
      pointsValue: pointsValue ?? this.pointsValue,
      passingScore: passingScore ?? this.passingScore,
      questions: questions ?? this.questions,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class QuizQuestion {
  final String questionText;
  final List<String> options;
  final int correctOptionIndex; // Zero-based index of the correct answer
  final String? explanation; // Optional explanation of the correct answer

  QuizQuestion({
    required this.questionText,
    required this.options,
    required this.correctOptionIndex,
    this.explanation,
  });

  // Create a QuizQuestion object from a map
  factory QuizQuestion.fromMap(Map<String, dynamic> map) {
    return QuizQuestion(
      questionText: map['questionText'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      correctOptionIndex: map['correctOptionIndex'] ?? 0,
      explanation: map['explanation'],
    );
  }

  // Create a map from a QuizQuestion object
  Map<String, dynamic> toMap() {
    return {
      'questionText': questionText,
      'options': options,
      'correctOptionIndex': correctOptionIndex,
      'explanation': explanation,
    };
  }

  // Get the correct answer text
  String get correctAnswer {
    if (correctOptionIndex >= 0 && correctOptionIndex < options.length) {
      return options[correctOptionIndex];
    }
    return '';
  }

  // Create a copy of the QuizQuestion with updated fields
  QuizQuestion copyWith({
    String? questionText,
    List<String>? options,
    int? correctOptionIndex,
    String? explanation,
  }) {
    return QuizQuestion(
      questionText: questionText ?? this.questionText,
      options: options ?? this.options,
      correctOptionIndex: correctOptionIndex ?? this.correctOptionIndex,
      explanation: explanation ?? this.explanation,
    );
  }
}
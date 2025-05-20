// File: lib/data/models/quiz_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/constants.dart';

class Quiz {
  final String id;
  final String title;
  final String description;
  final String contentId; // Associated lesson/content
  final List<QuizQuestion> questions;
  final int passingScore; // Minimum percentage to pass
  final int pointsPerQuestion;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  Quiz({
    required this.id,
    required this.title,
    required this.description,
    required this.contentId,
    required this.questions,
    this.passingScore = 60, // Default passing score: 60%
    this.pointsPerQuestion = AppConstants.defaultPointsPerQuizQuestion,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  // Calculate total possible points for this quiz
  int get totalPossiblePoints => questions.length * pointsPerQuestion;

  // Convert Quiz model to JSON format for Firestore
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'contentId': contentId,
      'questions': questions.map((question) => question.toJson()).toList(),
      'passingScore': passingScore,
      'pointsPerQuestion': pointsPerQuestion,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
    };
  }

  // Create Quiz model from Firestore document
  factory Quiz.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final List<dynamic> questionsData = data['questions'] ?? [];
    final List<QuizQuestion> questions = questionsData
        .map((questionData) => QuizQuestion.fromJson(questionData))
        .toList();

    return Quiz(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      contentId: data['contentId'] ?? '',
      questions: questions,
      passingScore: data['passingScore'] ?? 60,
      pointsPerQuestion: data['pointsPerQuestion'] ?? AppConstants.defaultPointsPerQuizQuestion,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      isActive: data['isActive'] ?? true,
    );
  }

  // Create Quiz model from JSON data
  factory Quiz.fromJson(Map<String, dynamic> json, String id) {
    final List<dynamic> questionsData = json['questions'] ?? [];
    final List<QuizQuestion> questions = questionsData
        .map((questionData) => QuizQuestion.fromJson(questionData))
        .toList();

    return Quiz(
      id: id,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      contentId: json['contentId'] ?? '',
      questions: questions,
      passingScore: json['passingScore'] ?? 60,
      pointsPerQuestion: json['pointsPerQuestion'] ?? AppConstants.defaultPointsPerQuizQuestion,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      isActive: json['isActive'] ?? true,
    );
  }

  // Create a copy of Quiz with modified fields
  Quiz copyWith({
    String? id,
    String? title,
    String? description,
    String? contentId,
    List<QuizQuestion>? questions,
    int? passingScore,
    int? pointsPerQuestion,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return Quiz(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      contentId: contentId ?? this.contentId,
      questions: questions ?? this.questions,
      passingScore: passingScore ?? this.passingScore,
      pointsPerQuestion: pointsPerQuestion ?? this.pointsPerQuestion,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}

class QuizQuestion {
  final String id;
  final String questionText;
  final String questionType; // multiple_choice, true_false, matching
  final List<QuizOption> options;
  final List<String> correctAnswers; // IDs of correct options
  final String? explanation; // Explanation shown after answering
  final Map<String, dynamic>? metadata;

  QuizQuestion({
    required this.id,
    required this.questionText,
    required this.questionType,
    required this.options,
    required this.correctAnswers,
    this.explanation,
    this.metadata,
  });

  // Convert QuizQuestion model to JSON format
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'questionText': questionText,
      'questionType': questionType,
      'options': options.map((option) => option.toJson()).toList(),
      'correctAnswers': correctAnswers,
      'explanation': explanation,
      'metadata': metadata,
    };
  }

  // Create QuizQuestion model from JSON data
  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    final List<dynamic> optionsData = json['options'] ?? [];
    final List<QuizOption> options = optionsData
        .map((optionData) => QuizOption.fromJson(optionData))
        .toList();

    return QuizQuestion(
      id: json['id'] ?? '',
      questionText: json['questionText'] ?? '',
      questionType: json['questionType'] ?? AppConstants.questionTypeMultipleChoice,
      options: options,
      correctAnswers: json['correctAnswers'] != null
          ? List<String>.from(json['correctAnswers'])
          : [],
      explanation: json['explanation'],
      metadata: json['metadata'],
    );
  }

  // Check if a given answer is correct
  bool isCorrect(List<String> selectedOptionIds) {
    // For multiple choice with multiple correct answers
    if (questionType == AppConstants.questionTypeMultipleChoice && correctAnswers.length > 1) {
      // All correct options must be selected and no incorrect ones
      return selectedOptionIds.length == correctAnswers.length &&
          selectedOptionIds.every((optionId) => correctAnswers.contains(optionId));
    }
    // For true/false or multiple choice with one correct answer
    else if (questionType == AppConstants.questionTypeTrueFalse ||
        questionType == AppConstants.questionTypeMultipleChoice) {
      // One correct option must be selected
      return selectedOptionIds.length == 1 && correctAnswers.contains(selectedOptionIds[0]);
    }
    // For matching questions (not fully implemented in this MVP)
    else if (questionType == AppConstants.questionTypeMatching) {
      // Matching logic would go here
      return false;
    }

    return false;
  }
}

class QuizOption {
  final String id;
  final String text;
  final Map<String, dynamic>? metadata;

  QuizOption({
    required this.id,
    required this.text,
    this.metadata,
  });

  // Convert QuizOption model to JSON format
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'metadata': metadata,
    };
  }

  // Create QuizOption model from JSON data
  factory QuizOption.fromJson(Map<String, dynamic> json) {
    return QuizOption(
      id: json['id'] ?? '',
      text: json['text'] ?? '',
      metadata: json['metadata'],
    );
  }
}
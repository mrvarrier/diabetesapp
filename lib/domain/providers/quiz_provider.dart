// File: lib/domain/providers/quiz_provider.dart

import 'package:flutter/foundation.dart';
import '../../data/models/quiz_model.dart';
import '../../data/services/database_service.dart';
import '../../data/services/local_storage_service.dart';

class QuizProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final LocalStorageService _localStorageService = LocalStorageService();

  List<Quiz> _quizzes = [];
  Quiz? _selectedQuiz;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Quiz> get quizzes => _quizzes;
  Quiz? get selectedQuiz => _selectedQuiz;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load all quizzes
  Future<void> loadAllQuizzes() async {
    _setLoading(true);

    try {
      // First try to get quizzes from Firestore
      try {
        final remoteQuizzes = await _databaseService.getAllQuizzes();

        if (remoteQuizzes.isNotEmpty) {
          // Save to local storage
          await _localStorageService.saveQuizzes(remoteQuizzes);

          // Update in-memory quizzes
          _quizzes = remoteQuizzes;

          notifyListeners();
          _setLoading(false);
          return;
        }
      } catch (e) {
        // If remote fetch fails, continue with local quizzes
      }

      // No remote quizzes or fetch failed, try to get from local storage
      // For this MVP, we'll just fail if no remote quizzes are available
      _quizzes = [];
      _error = 'No quizzes available. Please check your connection and try again.';
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Get quiz by ID
  Future<Quiz?> getQuizById(String quizId) async {
    try {
      // First check if it's in memory
      final memoryQuiz = _quizzes.firstWhere(
            (quiz) => quiz.id == quizId,
        orElse: () => null as Quiz, // Using null as Quiz for empty case (will cause runtime error and be caught)
      );

      if (memoryQuiz != null) {
        _selectedQuiz = memoryQuiz;
        notifyListeners();
        return memoryQuiz;
      }

      // Try to get from local storage
      final localQuiz = await _localStorageService.getQuizById(quizId);
      if (localQuiz != null) {
        _selectedQuiz = localQuiz;
        notifyListeners();
        return localQuiz;
      }

      // Try to get from Firestore
      final remoteQuiz = await _databaseService.getQuizById(quizId);
      if (remoteQuiz != null) {
        // Save to local storage
        await _localStorageService.saveQuizzes([remoteQuiz]);

        _selectedQuiz = remoteQuiz;
        notifyListeners();
        return remoteQuiz;
      }

      return null;
    } catch (e) {
      _error = e.toString();
      return null;
    }
  }

  // Get quiz by content ID
  Future<Quiz?> getQuizByContentId(String contentId) async {
    try {
      // First check if it's in memory
      final memoryQuiz = _quizzes.firstWhere(
            (quiz) => quiz.contentId == contentId,
        orElse: () => null as Quiz, // Using null as Quiz for empty case (will cause runtime error and be caught)
      );

      if (memoryQuiz != null) {
        _selectedQuiz = memoryQuiz;
        notifyListeners();
        return memoryQuiz;
      }

      // Try to get from local storage
      final localQuiz = await _localStorageService.getQuizByContentId(contentId);
      if (localQuiz != null) {
        _selectedQuiz = localQuiz;
        notifyListeners();
        return localQuiz;
      }

      // Try to get from Firestore
      final remoteQuiz = await _databaseService.getQuizByContentId(contentId);
      if (remoteQuiz != null) {
        // Save to local storage
        await _localStorageService.saveQuizzes([remoteQuiz]);

        _selectedQuiz = remoteQuiz;
        notifyListeners();
        return remoteQuiz;
      }

      return null;
    } catch (e) {
      _error = e.toString();
      return null;
    }
  }

  // Set selected quiz
  void setSelectedQuiz(Quiz quiz) {
    _selectedQuiz = quiz;
    notifyListeners();
  }

  // Clear selected quiz
  void clearSelectedQuiz() {
    _selectedQuiz = null;
    notifyListeners();
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
// File: lib/domain/providers/progress_provider.dart

import 'package:flutter/foundation.dart';
import '../../data/models/progress_model.dart';
import '../../data/models/content_model.dart';
import '../../data/services/database_service.dart';
import '../../data/services/local_storage_service.dart';
import '../providers/auth_provider.dart';

class ProgressProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final LocalStorageService _localStorageService = LocalStorageService();

  String? _userId;
  List<Progress> _progressList = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Progress> get progressList => _progressList;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Update with auth provider
  void update(AuthProvider authProvider) {
    final newUserId = authProvider.userId;

    // Only reload if user ID changed
    if (newUserId != _userId) {
      _userId = newUserId;

      if (_userId != null) {
        loadUserProgress(_userId!);
      } else {
        _progressList = [];
        notifyListeners();
      }
    }
  }

  // Load user progress
  Future<void> loadUserProgress(String userId) async {
    if (userId.isEmpty) return;

    _setLoading(true);

    try {
      // Try to get progress from local storage first
      final localProgress = await _localStorageService.getAllProgress();

      if (localProgress.isNotEmpty) {
        // Filter progress for current user
        _progressList = localProgress
            .where((progress) => progress.userId == userId)
            .toList();

        notifyListeners();
      }

      // Try to get updated progress from Firestore
      try {
        final remoteProgress = await _databaseService.getUserProgress(userId);

        if (remoteProgress.isNotEmpty) {
          // Save to local storage
          for (final progress in remoteProgress) {
            await _localStorageService.saveProgress(progress);
          }

          // Update in-memory progress list
          _progressList = remoteProgress;

          notifyListeners();
        }
      } catch (e) {
        // If remote fetch fails, continue with local progress
        // We already set _progressList from local storage
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Get progress for a specific content
  Future<Progress?> getContentProgress(String contentId) async {
    if (_userId == null) return null;

    try {
      // Check if it's already in the loaded progress
      for (final progress in _progressList) {
        if (progress.contentId == contentId) {
          return progress;
        }
      }

      // Try to get from local storage
      final localProgress = await _localStorageService.getContentProgress(
        _userId!,
        contentId,
      );

      if (localProgress != null) {
        return localProgress;
      }

      // Try to get from Firestore
      try {
        final remoteProgress = await _databaseService.getContentProgress(
          _userId!,
          contentId,
        );

        if (remoteProgress != null) {
          // Save to local storage
          await _localStorageService.saveProgress(remoteProgress);

          // Add to in-memory list
          _progressList.add(remoteProgress);
          notifyListeners();

          return remoteProgress;
        }
      } catch (e) {
        // If remote fetch fails, just return null
      }

      return null;
    } catch (e) {
      _error = e.toString();
      return null;
    }
  }

  // Start or continue progress for a content
  Future<Progress> startContentProgress(Content content) async {
    if (_userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Check if progress already exists
      final existingProgress = await getContentProgress(content.id);

      if (existingProgress != null) {
        // Update last interaction time
        final updatedProgress = existingProgress.copyWith(
          lastInteractionAt: DateTime.now(),
        );

        // Save to local storage
        await _localStorageService.saveProgress(updatedProgress);

        // Try to update on Firestore
        try {
          await _databaseService.updateProgress(updatedProgress);
        } catch (e) {
          // If remote update fails, continue with local update
        }

        // Update in-memory list
        final index = _progressList.indexWhere((p) => p.id == updatedProgress.id);
        if (index != -1) {
          _progressList[index] = updatedProgress;
        } else {
          _progressList.add(updatedProgress);
        }

        notifyListeners();

        return updatedProgress;
      } else {
        // Create new progress
        final newProgress = Progress.initial(
          userId: _userId!,
          contentId: content.id,
        );

        // Save to local storage
        await _localStorageService.saveProgress(newProgress);

        // Try to create on Firestore
        try {
          final createdProgress = await _databaseService.createProgress(newProgress);

          // Add to in-memory list
          _progressList.add(createdProgress);

          notifyListeners();

          return createdProgress;
        } catch (e) {
          // If remote creation fails, continue with local creation

          // Add to in-memory list
          _progressList.add(newProgress);

          notifyListeners();

          return newProgress;
        }
      }
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  // Update video progress
  Future<Progress> updateVideoProgress({
    required String contentId,
    required int currentPosition,
    required int totalDuration,
    required bool isCompleted,
    required int pointsToAward,
  }) async {
    if (_userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Get existing progress
      final existingProgress = await getContentProgress(contentId);

      if (existingProgress == null) {
        throw Exception('Progress not found');
      }

      // Calculate points based on completion
      int pointsEarned = 0;
      if (isCompleted && !existingProgress.isCompleted) {
        pointsEarned = pointsToAward;
      }

      // Update progress
      final updatedProgress = existingProgress.updateVideoProgress(
        currentPosition: currentPosition,
        totalDuration: totalDuration,
        isCompleted: isCompleted,
      ).copyWith(
        pointsEarned: existingProgress.pointsEarned + pointsEarned,
        completedAt: isCompleted && existingProgress.completedAt == null
            ? DateTime.now()
            : existingProgress.completedAt,
      );

      // Save to local storage
      await _localStorageService.saveProgress(updatedProgress);

      // Try to update on Firestore
      try {
        await _databaseService.updateProgress(updatedProgress);
      } catch (e) {
        // If remote update fails, continue with local update
      }

      // Update in-memory list
      final index = _progressList.indexWhere((p) => p.id == updatedProgress.id);
      if (index != -1) {
        _progressList[index] = updatedProgress;
      } else {
        _progressList.add(updatedProgress);
      }

      notifyListeners();

      return updatedProgress;
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  // Update quiz results
  Future<Progress> updateQuizResults({
    required String contentId,
    required int score,
    required int totalPossible,
    required bool isPassed,
    required int pointsPerQuestion,
  }) async {
    if (_userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Get existing progress
      final existingProgress = await getContentProgress(contentId);

      if (existingProgress == null) {
        throw Exception('Progress not found');
      }

      // Calculate points earned
      final pointsEarned = isPassed ? score * pointsPerQuestion : 0;

      // Update progress
      final updatedProgress = existingProgress.updateQuizResults(
        score: score,
        totalPossible: totalPossible,
        isPassed: isPassed,
        pointsEarned: pointsEarned,
      );

      // Save to local storage
      await _localStorageService.saveProgress(updatedProgress);

      // Try to update on Firestore
      try {
        await _databaseService.updateProgress(updatedProgress);
      } catch (e) {
        // If remote update fails, continue with local update
      }

      // Update in-memory list
      final index = _progressList.indexWhere((p) => p.id == updatedProgress.id);
      if (index != -1) {
        _progressList[index] = updatedProgress;
      } else {
        _progressList.add(updatedProgress);
      }

      notifyListeners();

      return updatedProgress;
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  // Calculate user completion statistics
  Map<String, dynamic> calculateCompletionStats(List<Content> allContents) {
    if (_progressList.isEmpty || allContents.isEmpty) {
      return {
        'completedCount': 0,
        'totalCount': allContents.length,
        'completionPercentage': 0.0,
        'totalPointsEarned': 0,
      };
    }

    // Count completed contents
    int completedCount = 0;
    int totalPointsEarned = 0;

    for (final progress in _progressList) {
      if (progress.isCompleted) {
        completedCount++;
      }
      totalPointsEarned += progress.pointsEarned;
    }

    // Calculate completion percentage
    final completionPercentage = allContents.isEmpty
        ? 0.0
        : (completedCount / allContents.length) * 100;

    return {
      'completedCount': completedCount,
      'totalCount': allContents.length,
      'completionPercentage': completionPercentage,
      'totalPointsEarned': totalPointsEarned,
    };
  }

  // Check if user has completed a lesson today
  Future<bool> hasCompletedLessonToday() async {
    if (_userId == null) return false;

    try {
      return await _databaseService.hasCompletedLessonToday(_userId!);
    } catch (e) {
      // If remote check fails, check local data
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      for (final progress in _progressList) {
        if (progress.isCompleted && progress.completedAt != null) {
          final completedDate = DateTime(
            progress.completedAt!.year,
            progress.completedAt!.month,
            progress.completedAt!.day,
          );

          if (completedDate.isAtSameMomentAs(today)) {
            return true;
          }
        }
      }

      return false;
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
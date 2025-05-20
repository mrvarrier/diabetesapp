// File: lib/domain/providers/achievements_provider.dart

import 'package:flutter/foundation.dart';
import '../../config/constants.dart';
import '../../data/models/achievement_model.dart';
import '../../data/services/database_service.dart';
import '../../data/services/local_storage_service.dart';
import '../../data/services/notification_service.dart';
import '../providers/auth_provider.dart';

class AchievementsProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final LocalStorageService _localStorageService = LocalStorageService();
  final NotificationService _notificationService = NotificationService();

  String? _userId;
  List<Achievement> _achievements = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Achievement> get achievements => _achievements;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Update with auth provider
  void update(AuthProvider authProvider) {
    final newUserId = authProvider.userId;

    // Only reload if user ID changed
    if (newUserId != _userId) {
      _userId = newUserId;

      if (_userId != null) {
        loadUserAchievements(_userId!);
      } else {
        _achievements = [];
        notifyListeners();
      }
    }
  }

  // Load user achievements
  Future<void> loadUserAchievements(String userId) async {
    if (userId.isEmpty) return;

    _setLoading(true);

    try {
      // Try to get achievements from local storage first
      final localAchievements = await _localStorageService.getUserAchievements(userId);

      if (localAchievements.isNotEmpty) {
        _achievements = localAchievements;
        notifyListeners();
      }

      // Try to get updated achievements from Firestore
      try {
        final remoteAchievements = await _databaseService.getUserAchievements(userId);

        if (remoteAchievements.isNotEmpty) {
          // Save to local storage
          await _localStorageService.saveAchievements(remoteAchievements);

          // Update in-memory achievements
          _achievements = remoteAchievements;

          notifyListeners();
        }
      } catch (e) {
        // If remote fetch fails, continue with local achievements
        // We already set _achievements from local storage
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Check if user has an achievement
  bool hasAchievement(String achievementType) {
    return _achievements.any((a) => a.achievementType == achievementType);
  }

  // Award achievement if not already earned
  Future<Achievement?> awardAchievementIfNotEarned(String achievementType) async {
    if (_userId == null) return null;

    // Check if already earned
    if (hasAchievement(achievementType)) {
      return _achievements.firstWhere((a) => a.achievementType == achievementType);
    }

    try {
      // Create achievement
      final achievement = Achievement.create(
        userId: _userId!,
        achievementType: achievementType,
      );

      // Try to save to Firestore
      try {
        final savedAchievement = await _databaseService.addAchievement(achievement);

        // Update local list
        _achievements.add(savedAchievement);

        // Save to local storage
        await _localStorageService.saveAchievements(_achievements);

        // Show notification
        await _showAchievementNotification(savedAchievement);

        notifyListeners();

        return savedAchievement;
      } catch (e) {
        // If Firestore save fails, save locally
        _achievements.add(achievement);

        // Save to local storage
        await _localStorageService.saveAchievements(_achievements);

        // Show notification
        await _showAchievementNotification(achievement);

        notifyListeners();

        return achievement;
      }
    } catch (e) {
      _error = e.toString();
      return null;
    }
  }

  // Check and award achievements based on progress
  Future<void> checkAndAwardAchievements({
    bool isFirstLesson = false,
    bool isPerfectQuiz = false,
    bool isPlanCompleted = false,
    int? currentPoints,
    int? streakDays,
  }) async {
    if (_userId == null) return;

    // First lesson achievement
    if (isFirstLesson && !hasAchievement(AppConstants.achievementFirstLesson)) {
      await awardAchievementIfNotEarned(AppConstants.achievementFirstLesson);
    }

    // Perfect quiz achievement
    if (isPerfectQuiz && !hasAchievement(AppConstants.achievementPerfectQuiz)) {
      await awardAchievementIfNotEarned(AppConstants.achievementPerfectQuiz);
    }

    // Plan completion achievement
    if (isPlanCompleted && !hasAchievement(AppConstants.achievementCompletePlan)) {
      await awardAchievementIfNotEarned(AppConstants.achievementCompletePlan);
    }

    // Points achievements
    if (currentPoints != null) {
      if (currentPoints >= 1000 && !hasAchievement(AppConstants.achievement1000Points)) {
        await awardAchievementIfNotEarned(AppConstants.achievement1000Points);
      } else if (currentPoints >= 500 && !hasAchievement(AppConstants.achievement500Points)) {
        await awardAchievementIfNotEarned(AppConstants.achievement500Points);
      } else if (currentPoints >= 100 && !hasAchievement(AppConstants.achievement100Points)) {
        await awardAchievementIfNotEarned(AppConstants.achievement100Points);
      }
    }

    // Streak achievements
    if (streakDays != null) {
      if (streakDays >= 7 && !hasAchievement(AppConstants.achievement7DayStreak)) {
        await awardAchievementIfNotEarned(AppConstants.achievement7DayStreak);
      } else if (streakDays >= 3 && !hasAchievement(AppConstants.achievement3DayStreak)) {
        await awardAchievementIfNotEarned(AppConstants.achievement3DayStreak);
      }
    }
  }

  // Show achievement notification
  Future<void> _showAchievementNotification(Achievement achievement) async {
    await _notificationService.showAchievementNotification(
      title: 'Achievement Unlocked!',
      body: '${achievement.title}: ${achievement.description}',
      payload: achievement.achievementType,
    );
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
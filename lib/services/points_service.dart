import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'database_service.dart';
import 'notification_service.dart';
import '../constants/string_constants.dart';

class PointsService extends ChangeNotifier {
  final DatabaseService _databaseService;
  final NotificationService _notificationService;

  // Points values for different activities
  static const int VIDEO_COMPLETION_POINTS = 10;
  static const int QUIZ_COMPLETION_POINTS = 15;
  static const int PERFECT_QUIZ_BONUS = 10;
  static const int DAILY_STREAK_POINTS = 5;
  static const int WEEKLY_STREAK_POINTS = 20;
  static const int MONTHLY_STREAK_POINTS = 100;

  int _currentPoints = 0;
  int _currentStreak = 0;

  PointsService({
    required DatabaseService databaseService,
    required NotificationService notificationService,
  }) :
        _databaseService = databaseService,
        _notificationService = notificationService;

  // Getters for current points and streak
  int get currentPoints => _currentPoints;
  int get currentStreak => _currentStreak;

  // Load user's current points and streak
  Future<void> loadUserPoints() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    final userModel = await _databaseService.getUser(user.uid);
    if (userModel != null) {
      _currentPoints = userModel.points;
      _currentStreak = userModel.streakDays;
      notifyListeners();
    }
  }

  // Award points for watching a video
  Future<void> awardVideoPoints(String contentId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    // Get the content to determine points value
    final content = await _databaseService.getContent(contentId);
    if (content == null) {
      return;
    }

    // Check if user has already completed this content
    final userModel = await _databaseService.getUser(user.uid);
    if (userModel == null || userModel.completedLessons.contains(contentId)) {
      return;
    }

    // Award points based on content value or default
    final pointsToAward = content.pointsValue > 0 ? content.pointsValue : VIDEO_COMPLETION_POINTS;

    // Update points in database
    await _databaseService.updateUserPoints(user.uid, pointsToAward);

    // Mark the content as completed
    await _databaseService.addCompletedLesson(user.uid, contentId);

    // Update progress record
    final progress = await _databaseService.getUserContentProgress(user.uid, contentId);
    if (progress != null) {
      await _databaseService.completeContentProgress(progress.id, pointsToAward);
    }

    // Update local state
    _currentPoints += pointsToAward;
    notifyListeners();

    // Create notification for points earned
    await _notificationService.createLocalNotification(
      title: StringConstants.pointsEarned,
      body: 'You earned $pointsToAward points for watching "${content.title}"!',
      payload: '/education-plan',
    );

    // Check for any unlocked achievements
    await checkAndAwardAchievements(user.uid);
  }

  // Award points for completing a quiz
  Future<int> awardQuizPoints(String contentId, int score, int totalQuestions) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return 0;
    }

    // Calculate percentage score
    final percentageScore = (score / totalQuestions) * 100;

    // Base points for completing the quiz
    int pointsToAward = QUIZ_COMPLETION_POINTS;

    // Bonus points for perfect score
    if (score == totalQuestions) {
      pointsToAward += PERFECT_QUIZ_BONUS;
    }

    // Update points in database
    await _databaseService.updateUserPoints(user.uid, pointsToAward);

    // Update local state
    _currentPoints += pointsToAward;
    notifyListeners();

    // Get the content for the notification
    final content = await _databaseService.getContent(contentId);

    // Create notification for points earned
    if (content != null) {
      await _notificationService.createLocalNotification(
        title: StringConstants.pointsEarned,
        body: 'You earned $pointsToAward points for completing the quiz for "${content.title}"!',
        payload: '/education-plan',
      );
    }

    // Check for any unlocked achievements
    await checkAndAwardAchievements(user.uid);

    return pointsToAward;
  }

  // Award points for maintaining a streak
  Future<void> awardStreakPoints() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    // Get current user data
    final userModel = await _databaseService.getUser(user.uid);
    if (userModel == null) {
      return;
    }

    // Update local state
    _currentStreak = userModel.streakDays;

    // Determine points based on streak milestone
    int pointsToAward = 0;
    String notificationTitle = '';
    String notificationBody = '';

    if (_currentStreak % 30 == 0) {
      // Monthly streak milestone
      pointsToAward = MONTHLY_STREAK_POINTS;
      notificationTitle = 'Amazing Monthly Streak!';
      notificationBody = 'Incredible! You've maintained your streak for ${_currentStreak} days! You earned $pointsToAward points!';
    } else if (_currentStreak % 7 == 0) {
      // Weekly streak milestone
      pointsToAward = WEEKLY_STREAK_POINTS;
      notificationTitle = 'Weekly Streak Achievement!';
      notificationBody = 'Great job! You've maintained your streak for ${_currentStreak} days! You earned $pointsToAward points!';
    } else {
      // Daily streak
      pointsToAward = DAILY_STREAK_POINTS;
      notificationTitle = 'Daily Streak Continues!';
      notificationBody = 'Well done! You've maintained your streak for ${_currentStreak} days! You earned $pointsToAward points!';
    }

    if (pointsToAward > 0) {
      // Update points in database
      await _databaseService.updateUserPoints(user.uid, pointsToAward);

      // Update local state
      _currentPoints += pointsToAward;
      notifyListeners();

      // Create notification
      await _notificationService.createLocalNotification(
        title: notificationTitle,
        body: notificationBody,
        payload: '/home',
      );

      // Check for any unlocked achievements
      await checkAndAwardAchievements(user.uid);
    }
  }

  // Check for and award any newly unlocked achievements
  Future<void> checkAndAwardAchievements(String userId) async {
    // Get newly unlocked achievements
    final newAchievements = await _databaseService.checkAndAwardAchievements(userId);

    // Create notifications for each new achievement
    for (var achievement in newAchievements) {
      await _notificationService.createLocalNotification(
        title: StringConstants.newAchievement,
        body: 'You\'ve unlocked "${achievement.title}" and earned ${achievement.pointsValue} points!',
        payload: '/achievements',
      );
    }

    // Refresh user points if achievements were unlocked
    if (newAchievements.isNotEmpty) {
      await loadUserPoints();
    }
  }

  // Get points history for user
  Future<List<Map<String, dynamic>>> getPointsHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return [];
    }

    // Get all progress records to build history
    final progressList = await _databaseService.getUserProgress(user.uid);

    List<Map<String, dynamic>> history = [];

    for (var progress in progressList) {
      if (progress.pointsEarned > 0) {
        // Get content details
        final content = await _databaseService.getContent(progress.contentId);

        if (content != null) {
          history.add({
            'date': progress.completionTime ?? progress.startTime,
            'title': content.title,
            'points': progress.pointsEarned,
            'type': 'content',
          });
        }
      }
    }

    // Sort by date (newest first)
    history.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

    return history;
  }

  // Get leaderboard data
  Future<List<Map<String, dynamic>>> getLeaderboard() async {
    // Get all users
    final users = await _databaseService.getAllUsers();

    // Create leaderboard entries
    List<Map<String, dynamic>> leaderboard = users.map((user) {
      return {
        'userId': user.uid,
        'name': user.fullName,
        'points': user.points,
        'streak': user.streakDays,
      };
    }).toList();

    // Sort by points (highest first)
    leaderboard.sort((a, b) => (b['points'] as int).compareTo(a['points'] as int));

    // Limit to top 50
    if (leaderboard.length > 50) {
      leaderboard = leaderboard.sublist(0, 50);
    }

    // Add ranks
    for (int i = 0; i < leaderboard.length; i++) {
      leaderboard[i]['rank'] = i + 1;
    }

    return leaderboard;
  }

  // Get user's leaderboard position
  Future<Map<String, dynamic>?> getUserLeaderboardPosition() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return null;
    }

    final leaderboard = await getLeaderboard();

    // Find user in leaderboard
    final userPosition = leaderboard.firstWhere(
          (entry) => entry['userId'] == user.uid,
      orElse: () => {},
    );

    if (userPosition.isEmpty) {
      return null;
    }

    return userPosition;
  }
}
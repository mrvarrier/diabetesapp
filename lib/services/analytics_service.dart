import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  final CollectionReference _analyticsCollection =
  FirebaseFirestore.instance.collection('analytics');

  // User properties
  static const String PROPERTY_DIABETES_TYPE = 'diabetes_type';
  static const String PROPERTY_TREATMENT_METHOD = 'treatment_method';
  static const String PROPERTY_AGE_GROUP = 'age_group';

  // Event names
  static const String EVENT_LESSON_START = 'lesson_start';
  static const String EVENT_LESSON_COMPLETE = 'lesson_complete';
  static const String EVENT_QUIZ_START = 'quiz_start';
  static const String EVENT_QUIZ_COMPLETE = 'quiz_complete';
  static const String EVENT_ACHIEVEMENT_UNLOCKED = 'achievement_unlocked';
  static const String EVENT_STREAK_MILESTONE = 'streak_milestone';
  static const String EVENT_VIEW_PROGRESS = 'view_progress';
  static const String EVENT_PROVIDE_FEEDBACK = 'provide_feedback';
  static const String EVENT_VIDEO_COMPLETE = 'video_complete';
  static const String EVENT_SESSION_START = 'session_start';
  static const String EVENT_SESSION_END = 'session_end';
  static const String EVENT_FEATURE_USE = 'feature_use';

  // Initialize analytics
  Future<void> init() async {
    // Enable analytics debug mode in development
    if (kDebugMode) {
      await _analytics.setAnalyticsCollectionEnabled(true);
    }

    // Start session
    await logSessionStart();
  }

  // Set user properties
  Future<void> setUserProperties({
    String? diabetesType,
    String? treatmentMethod,
    int? age,
  }) async {
    if (diabetesType != null) {
      await _analytics.setUserProperty(
        name: PROPERTY_DIABETES_TYPE,
        value: diabetesType,
      );
    }

    if (treatmentMethod != null) {
      await _analytics.setUserProperty(
        name: PROPERTY_TREATMENT_METHOD,
        value: treatmentMethod,
      );
    }

    if (age != null) {
      String ageGroup;

      // Determine age group
      if (age < 18) {
        ageGroup = 'under_18';
      } else if (age < 30) {
        ageGroup = '18_29';
      } else if (age < 45) {
        ageGroup = '30_44';
      } else if (age < 60) {
        ageGroup = '45_59';
      } else {
        ageGroup = '60_plus';
      }

      await _analytics.setUserProperty(
        name: PROPERTY_AGE_GROUP,
        value: ageGroup,
      );
    }
  }

  // Log session start
  Future<void> logSessionStart() async {
    await _analytics.logEvent(
      name: EVENT_SESSION_START,
      parameters: {
        'timestamp': FieldValue.serverTimestamp().toString(),
      },
    );

    // Record session start in Firestore for custom analytics
    await _recordSessionInFirestore(true);
  }

  // Log session end
  Future<void> logSessionEnd() async {
    await _analytics.logEvent(
      name: EVENT_SESSION_END,
      parameters: {
        'timestamp': FieldValue.serverTimestamp().toString(),
      },
    );

    // Record session end in Firestore for custom analytics
    await _recordSessionInFirestore(false);
  }

  // Record session in Firestore
  Future<void> _recordSessionInFirestore(bool isStart) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    await _analyticsCollection.add({
      'userId': user.uid,
      'event': isStart ? EVENT_SESSION_START : EVENT_SESSION_END,
      'timestamp': FieldValue.serverTimestamp(),
      'platform': defaultTargetPlatform.toString(),
    });
  }

  // Log lesson start
  Future<void> logLessonStart(String lessonId, String lessonTitle) async {
    await _analytics.logEvent(
      name: EVENT_LESSON_START,
      parameters: {
        'lesson_id': lessonId,
        'lesson_title': lessonTitle,
      },
    );

    // Record in Firestore
    await _recordEventInFirestore(
      EVENT_LESSON_START,
      {
        'lessonId': lessonId,
        'lessonTitle': lessonTitle,
      },
    );
  }

  // Log lesson completion
  Future<void> logLessonComplete(
      String lessonId,
      String lessonTitle,
      int pointsEarned,
      int durationSeconds,
      ) async {
    await _analytics.logEvent(
      name: EVENT_LESSON_COMPLETE,
      parameters: {
        'lesson_id': lessonId,
        'lesson_title': lessonTitle,
        'points_earned': pointsEarned,
        'duration_seconds': durationSeconds,
      },
    );

    // Record in Firestore
    await _recordEventInFirestore(
      EVENT_LESSON_COMPLETE,
      {
        'lessonId': lessonId,
        'lessonTitle': lessonTitle,
        'pointsEarned': pointsEarned,
        'durationSeconds': durationSeconds,
      },
    );
  }

  // Log quiz start
  Future<void> logQuizStart(String quizId, String contentId) async {
    await _analytics.logEvent(
      name: EVENT_QUIZ_START,
      parameters: {
        'quiz_id': quizId,
        'content_id': contentId,
      },
    );

    // Record in Firestore
    await _recordEventInFirestore(
      EVENT_QUIZ_START,
      {
        'quizId': quizId,
        'contentId': contentId,
      },
    );
  }

  // Log quiz completion
  Future<void> logQuizComplete(
      String quizId,
      String contentId,
      int score,
      int totalQuestions,
      bool passed,
      ) async {
    await _analytics.logEvent(
      name: EVENT_QUIZ_COMPLETE,
      parameters: {
        'quiz_id': quizId,
        'content_id': contentId,
        'score': score,
        'total_questions': totalQuestions,
        'passed': passed,
        'percentage': (score / totalQuestions) * 100,
      },
    );

    // Record in Firestore
    await _recordEventInFirestore(
      EVENT_QUIZ_COMPLETE,
      {
        'quizId': quizId,
        'contentId': contentId,
        'score': score,
        'totalQuestions': totalQuestions,
        'passed': passed,
        'percentage': (score / totalQuestions) * 100,
      },
    );
  }

  // Log achievement unlocked
  Future<void> logAchievementUnlocked(
      String achievementId,
      String achievementTitle,
      int pointsEarned,
      ) async {
    await _analytics.logEvent(
      name: EVENT_ACHIEVEMENT_UNLOCKED,
      parameters: {
        'achievement_id': achievementId,
        'achievement_title': achievementTitle,
        'points_earned': pointsEarned,
      },
    );

    // Record in Firestore
    await _recordEventInFirestore(
      EVENT_ACHIEVEMENT_UNLOCKED,
      {
        'achievementId': achievementId,
        'achievementTitle': achievementTitle,
        'pointsEarned': pointsEarned,
      },
    );
  }

  // Log streak milestone
  Future<void> logStreakMilestone(int streakDays) async {
    await _analytics.logEvent(
      name: EVENT_STREAK_MILESTONE,
      parameters: {
        'streak_days': streakDays,
      },
    );

    // Record in Firestore
    await _recordEventInFirestore(
      EVENT_STREAK_MILESTONE,
      {
        'streakDays': streakDays,
      },
    );
  }

  // Log video complete
  Future<void> logVideoComplete(
      String videoId,
      String contentId,
      int durationSeconds,
      int watchedSeconds,
      ) async {
    await _analytics.logEvent(
      name: EVENT_VIDEO_COMPLETE,
      parameters: {
        'video_id': videoId,
        'content_id': contentId,
        'duration_seconds': durationSeconds,
        'watched_seconds': watchedSeconds,
        'completion_percentage': (watchedSeconds / durationSeconds) * 100,
      },
    );

    // Record in Firestore
    await _recordEventInFirestore(
      EVENT_VIDEO_COMPLETE,
      {
        'videoId': videoId,
        'contentId': contentId,
        'durationSeconds': durationSeconds,
        'watchedSeconds': watchedSeconds,
        'completionPercentage': (watchedSeconds / durationSeconds) * 100,
      },
    );
  }

  // Log view progress
  Future<void> logViewProgress() async {
    await _analytics.logEvent(
      name: EVENT_VIEW_PROGRESS,
    );

    // Record in Firestore
    await _recordEventInFirestore(EVENT_VIEW_PROGRESS, {});
  }

  // Log provide feedback
  Future<void> logProvideFeedback(
      String contentId,
      int rating,
      bool hasComment,
      ) async {
    await _analytics.logEvent(
      name: EVENT_PROVIDE_FEEDBACK,
      parameters: {
        'content_id': contentId,
        'rating': rating,
        'has_comment': hasComment,
      },
    );

    // Record in Firestore
    await _recordEventInFirestore(
      EVENT_PROVIDE_FEEDBACK,
      {
        'contentId': contentId,
        'rating': rating,
        'hasComment': hasComment,
      },
    );
  }

  // Log feature use
  Future<void> logFeatureUse(String featureName) async {
    await _analytics.logEvent(
      name: EVENT_FEATURE_USE,
      parameters: {
        'feature_name': featureName,
      },
    );

    // Record in Firestore
    await _recordEventInFirestore(
      EVENT_FEATURE_USE,
      {
        'featureName': featureName,
      },
    );
  }

  // Record event in Firestore
  Future<void> _recordEventInFirestore(
      String eventName,
      Map<String, dynamic> parameters,
      ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    // Add common parameters
    parameters['userId'] = user.uid;
    parameters['event'] = eventName;
    parameters['timestamp'] = FieldValue.serverTimestamp();
    parameters['platform'] = defaultTargetPlatform.toString();

    // Record in analytics collection
    await _analyticsCollection.add(parameters);
  }

  // Get user engagement metrics
  Future<Map<String, dynamic>> getUserEngagementMetrics(String userId) async {
    try {
      // Get total sessions
      final sessionStartQuery = await _analyticsCollection
          .where('userId', isEqualTo: userId)
          .where('event', isEqualTo: EVENT_SESSION_START)
          .get();

      int totalSessions = sessionStartQuery.docs.length;

      // Get completed lessons
      final lessonCompleteQuery = await _analyticsCollection
          .where('userId', isEqualTo: userId)
          .where('event', isEqualTo: EVENT_LESSON_COMPLETE)
          .get();

      int completedLessons = lessonCompleteQuery.docs.length;

      // Get completed quizzes
      final quizCompleteQuery = await _analyticsCollection
          .where('userId', isEqualTo: userId)
          .where('event', isEqualTo: EVENT_QUIZ_COMPLETE)
          .get();

      int completedQuizzes = quizCompleteQuery.docs.length;

      // Calculate average quiz score
      double averageQuizScore = 0;
      if (completedQuizzes > 0) {
        double totalScore = 0;
        for (var doc in quizCompleteQuery.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          if (data['percentage'] != null) {
            totalScore += (data['percentage'] as num).toDouble();
          }
        }
        averageQuizScore = totalScore / completedQuizzes;
      }

      // Get video completions
      final videoCompleteQuery = await _analyticsCollection
          .where('userId', isEqualTo: userId)
          .where('event', isEqualTo: EVENT_VIDEO_COMPLETE)
          .get();

      int completedVideos = videoCompleteQuery.docs.length;

      // Calculate total learning time in minutes
      int totalLearningMinutes = 0;
      for (var doc in lessonCompleteQuery.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data['durationSeconds'] != null) {
          totalLearningMinutes += ((data['durationSeconds'] as num) / 60).round();
        }
      }

      return {
        'totalSessions': totalSessions,
        'completedLessons': completedLessons,
        'completedQuizzes': completedQuizzes,
        'averageQuizScore': averageQuizScore,
        'completedVideos': completedVideos,
        'totalLearningMinutes': totalLearningMinutes,
      };
    } catch (e) {
      print('Error getting engagement metrics: $e');
      return {
        'totalSessions': 0,
        'completedLessons': 0,
        'completedQuizzes': 0,
        'averageQuizScore': 0,
        'completedVideos': 0,
        'totalLearningMinutes': 0,
      };
    }
  }

  // Get platform-wide analytics for admins
  Future<Map<String, dynamic>> getPlatformAnalytics() async {
    try {
      // Get total users
      final usersQuery = await FirebaseFirestore.instance
          .collection('users')
          .get();

      int totalUsers = usersQuery.docs.length;

      // Get active users (had a session in the last 7 days)
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final activeUsersQuery = await _analyticsCollection
          .where('event', isEqualTo: EVENT_SESSION_START)
          .where('timestamp', isGreaterThan: sevenDaysAgo)
          .get();

      // Get unique user IDs
      Set<String> activeUserIds = {};
      for (var doc in activeUsersQuery.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data['userId'] != null) {
          activeUserIds.add(data['userId'] as String);
        }
      }

      int activeUsers = activeUserIds.length;

      // Get total lessons completed
      final lessonsQuery = await _analyticsCollection
          .where('event', isEqualTo: EVENT_LESSON_COMPLETE)
          .get();

      int totalCompletedLessons = lessonsQuery.docs.length;

      // Get total quiz completions
      final quizzesQuery = await _analyticsCollection
          .where('event', isEqualTo: EVENT_QUIZ_COMPLETE)
          .get();

      int totalCompletedQuizzes = quizzesQuery.docs.length;

      // Get average quiz score
      double totalQuizScore = 0;
      for (var doc in quizzesQuery.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data['percentage'] != null) {
          totalQuizScore += (data['percentage'] as num).toDouble();
        }
      }

      double averageQuizScore = totalCompletedQuizzes > 0
          ? totalQuizScore / totalCompletedQuizzes
          : 0;

      // Get content engagement (which lessons are most completed)
      Map<String, int> contentEngagement = {};

      for (var doc in lessonsQuery.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data['lessonId'] != null) {
          String lessonId = data['lessonId'] as String;
          contentEngagement[lessonId] = (contentEngagement[lessonId] ?? 0) + 1;
        }
      }

      // Get platform distribution
      Map<String, int> platformDistribution = {};

      final platformQuery = await _analyticsCollection
          .where('event', isEqualTo: EVENT_SESSION_START)
          .get();

      for (var doc in platformQuery.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data['platform'] != null) {
          String platform = data['platform'] as String;
          platformDistribution[platform] = (platformDistribution[platform] ?? 0) + 1;
        }
      }

      return {
        'totalUsers': totalUsers,
        'activeUsers': activeUsers,
        'totalCompletedLessons': totalCompletedLessons,
        'totalCompletedQuizzes': totalCompletedQuizzes,
        'averageQuizScore': averageQuizScore,
        'contentEngagement': contentEngagement,
        'platformDistribution': platformDistribution,
      };
    } catch (e) {
      print('Error getting platform analytics: $e');
      return {
        'totalUsers': 0,
        'activeUsers': 0,
        'totalCompletedLessons': 0,
        'totalCompletedQuizzes': 0,
        'averageQuizScore': 0,
        'contentEngagement': {},
        'platformDistribution': {},
      };
    }
  }
}
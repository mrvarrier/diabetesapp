import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/content_model.dart';
import '../models/quiz_model.dart';
import '../models/progress_model.dart';
import '../models/achievement_model.dart';
import '../models/notification_model.dart';
import '../models/feedback_model.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _usersCollection => _firestore.collection('users');
  CollectionReference get _contentCollection => _firestore.collection('content');
  CollectionReference get _modulesCollection => _firestore.collection('modules');
  CollectionReference get _quizCollection => _firestore.collection('quizzes');
  CollectionReference get _progressCollection => _firestore.collection('progress');
  CollectionReference get _achievementsCollection => _firestore.collection('achievements');
  CollectionReference get _notificationsCollection => _firestore.collection('notifications');
  CollectionReference get _feedbackCollection => _firestore.collection('feedback');
  CollectionReference get _educationPlansCollection => _firestore.collection('education_plans');

  // USER OPERATIONS

  // Get user data stream by UID
  Stream<UserModel?> getUserStream(String uid) {
    return _usersCollection.doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return UserModel.fromFirestore(snapshot);
      }
      return null;
    });
  }

  // Get user data by UID
  Future<UserModel?> getUser(String uid) async {
    DocumentSnapshot doc = await _usersCollection.doc(uid).get();
    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }
    return null;
  }

  // Update user points
  Future<void> updateUserPoints(String uid, int pointsToAdd) async {
    await _usersCollection.doc(uid).update({
      'points': FieldValue.increment(pointsToAdd),
    });
  }

  // Add achievement to user
  Future<void> addUserAchievement(String uid, String achievementId) async {
    await _usersCollection.doc(uid).update({
      'unlockedAchievements': FieldValue.arrayUnion([achievementId]),
    });
  }

  // Add completed lesson to user
  Future<void> addCompletedLesson(String uid, String contentId) async {
    await _usersCollection.doc(uid).update({
      'completedLessons': FieldValue.arrayUnion([contentId]),
    });
  }

  // CONTENT OPERATIONS

  // Get all modules for a specific plan
  Future<List<Map<String, dynamic>>> getModules(String planId) async {
    QuerySnapshot snapshot = await _modulesCollection
        .where('planId', isEqualTo: planId)
        .orderBy('sequenceNumber')
        .get();

    return snapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      return {
        'id': doc.id,
        ...data,
      };
    }).toList();
  }

  // Get all content for a specific module
  Future<List<ContentModel>> getModuleContent(String moduleId) async {
    QuerySnapshot snapshot = await _contentCollection
        .where('moduleId', isEqualTo: moduleId)
        .where('isActive', isEqualTo: true)
        .orderBy('sequenceNumber')
        .get();

    return snapshot.docs.map((doc) => ContentModel.fromFirestore(doc)).toList();
  }

  // Get a specific content by ID
  Future<ContentModel?> getContent(String contentId) async {
    DocumentSnapshot doc = await _contentCollection.doc(contentId).get();
    if (doc.exists) {
      return ContentModel.fromFirestore(doc);
    }
    return null;
  }

  // QUIZ OPERATIONS

  // Get quiz for a specific content
  Future<QuizModel?> getContentQuiz(String contentId) async {
    QuerySnapshot snapshot = await _quizCollection
        .where('contentId', isEqualTo: contentId)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return QuizModel.fromFirestore(snapshot.docs.first);
    }

    return null;
  }

  // PROGRESS OPERATIONS

  // Start progress tracking for a content
  Future<String> startContentProgress(String userId, String contentId) async {
    // Check if there's already a progress document
    QuerySnapshot existingProgress = await _progressCollection
        .where('userId', isEqualTo: userId)
        .where('contentId', isEqualTo: contentId)
        .limit(1)
        .get();

    if (existingProgress.docs.isNotEmpty) {
      return existingProgress.docs.first.id;
    }

    // Create new progress document
    DocumentReference progressRef = await _progressCollection.add({
      'userId': userId,
      'contentId': contentId,
      'isCompleted': false,
      'pointsEarned': 0,
      'startTime': FieldValue.serverTimestamp(),
      'watchTimeSeconds': 0,
      'metadata': {},
    });

    return progressRef.id;
  }

  // Update video watch time
  Future<void> updateWatchTime(String progressId, int watchTimeSeconds) async {
    await _progressCollection.doc(progressId).update({
      'watchTimeSeconds': watchTimeSeconds,
    });
  }

  // Complete content progress
  Future<void> completeContentProgress(String progressId, int pointsEarned) async {
    await _progressCollection.doc(progressId).update({
      'isCompleted': true,
      'pointsEarned': pointsEarned,
      'completionTime': FieldValue.serverTimestamp(),
    });
  }

  // Get user progress for a specific content
  Future<ProgressModel?> getUserContentProgress(String userId, String contentId) async {
    QuerySnapshot snapshot = await _progressCollection
        .where('userId', isEqualTo: userId)
        .where('contentId', isEqualTo: contentId)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return ProgressModel.fromFirestore(snapshot.docs.first);
    }

    return null;
  }

  // Get all progress for a user
  Future<List<ProgressModel>> getUserProgress(String userId) async {
    QuerySnapshot snapshot = await _progressCollection
        .where('userId', isEqualTo: userId)
        .get();

    return snapshot.docs.map((doc) => ProgressModel.fromFirestore(doc)).toList();
  }

  // ACHIEVEMENT OPERATIONS

  // Get all achievements
  Future<List<AchievementModel>> getAllAchievements() async {
    QuerySnapshot snapshot = await _achievementsCollection.get();
    return snapshot.docs.map((doc) => AchievementModel.fromFirestore(doc)).toList();
  }

  // Get specific achievement
  Future<AchievementModel?> getAchievement(String achievementId) async {
    DocumentSnapshot doc = await _achievementsCollection.doc(achievementId).get();
    if (doc.exists) {
      return AchievementModel.fromFirestore(doc);
    }
    return null;
  }

  // Check and award achievements for a user
  Future<List<AchievementModel>> checkAndAwardAchievements(String userId) async {
    // Get user data
    UserModel? user = await getUser(userId);
    if (user == null) {
      return [];
    }

    // Get all user progress
    List<ProgressModel> userProgress = await getUserProgress(userId);

    // Get all achievements
    List<AchievementModel> allAchievements = await getAllAchievements();

    // Filter to only get non-unlocked achievements
    List<AchievementModel> eligibleAchievements = allAchievements
        .where((achievement) => !user.unlockedAchievements.contains(achievement.id))
        .toList();

    // List to store newly unlocked achievements
    List<AchievementModel> newlyUnlocked = [];

    // Check each achievement's criteria
    for (var achievement in eligibleAchievements) {
      bool isUnlocked = false;

      switch (achievement.achievementType) {
        case 'streak':
          int requiredDays = achievement.criteria['days'] ?? 0;
          isUnlocked = user.streakDays >= requiredDays;
          break;

        case 'completion':
          int requiredLessons = achievement.criteria['lessonsCompleted'] ?? 0;
          isUnlocked = user.completedLessons.length >= requiredLessons;
          break;

        case 'points':
          int requiredPoints = achievement.criteria['points'] ?? 0;
          isUnlocked = user.points >= requiredPoints;
          break;

        case 'specific_content':
          String requiredContentId = achievement.criteria['contentId'] ?? '';
          isUnlocked = user.completedLessons.contains(requiredContentId);
          break;

      // Add more achievement types as needed
      }

      // If achievement is unlocked, award it to the user
      if (isUnlocked) {
        await addUserAchievement(userId, achievement.id);
        await updateUserPoints(userId, achievement.pointsValue);
        newlyUnlocked.add(achievement);
      }
    }

    return newlyUnlocked;
  }

  // NOTIFICATION OPERATIONS

  // Create a new notification
  Future<String> createNotification({
    required String userId,
    required String title,
    required String body,
    required String notificationType,
    Map<String, dynamic> data = const {},
    String? actionRoute,
  }) async {
    DocumentReference notificationRef = await _notificationsCollection.add({
      'userId': userId,
      'title': title,
      'body': body,
      'notificationType': notificationType,
      'data': data,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
      'actionRoute': actionRoute,
    });

    return notificationRef.id;
  }

  // Get unread notifications for a user
  Future<List<NotificationModel>> getUnreadNotifications(String userId) async {
    QuerySnapshot snapshot = await _notificationsCollection
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => NotificationModel.fromFirestore(doc)).toList();
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    await _notificationsCollection.doc(notificationId).update({
      'isRead': true,
    });
  }

  // FEEDBACK OPERATIONS

  // Submit feedback for content
  Future<void> submitFeedback({
    required String userId,
    required String contentId,
    required int rating,
    String? comment,
    Map<String, dynamic> metadata = const {},
  }) async {
    await _feedbackCollection.add({
      'userId': userId,
      'contentId': contentId,
      'rating': rating,
      'comment': comment,
      'createdAt': FieldValue.serverTimestamp(),
      'metadata': metadata,
    });
  }

  // Get content feedback statistics
  Future<Map<String, dynamic>> getContentFeedbackStats(String contentId) async {
    QuerySnapshot snapshot = await _feedbackCollection
        .where('contentId', isEqualTo: contentId)
        .get();

    if (snapshot.docs.isEmpty) {
      return {
        'averageRating': 0.0,
        'totalRatings': 0,
        'ratingCounts': {
          '1': 0,
          '2': 0,
          '3': 0,
          '4': 0,
          '5': 0,
        },
      };
    }

    List<FeedbackModel> feedbacks = snapshot.docs
        .map((doc) => FeedbackModel.fromFirestore(doc))
        .toList();

    // Calculate average rating
    double totalRating = feedbacks.fold(0, (sum, feedback) => sum + feedback.rating);
    double averageRating = totalRating / feedbacks.length;

    // Count ratings by value
    Map<String, int> ratingCounts = {
      '1': 0,
      '2': 0,
      '3': 0,
      '4': 0,
      '5': 0,
    };

    for (var feedback in feedbacks) {
      ratingCounts[feedback.rating.toString()] =
          (ratingCounts[feedback.rating.toString()] ?? 0) + 1;
    }

    return {
      'averageRating': averageRating,
      'totalRatings': feedbacks.length,
      'ratingCounts': ratingCounts,
    };
  }

  // EDUCATION PLAN OPERATIONS

  // Get education plan details
  Future<Map<String, dynamic>?> getEducationPlan(String planId) async {
    DocumentSnapshot doc = await _educationPlansCollection.doc(planId).get();
    if (doc.exists) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      return {
        'id': doc.id,
        ...data,
      };
    }
    return null;
  }

  // Get all available education plans
  Future<List<Map<String, dynamic>>> getAllEducationPlans() async {
    QuerySnapshot snapshot = await _educationPlansCollection.get();

    return snapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      return {
        'id': doc.id,
        ...data,
      };
    }).toList();
  }

  // Get plans suitable for a specific diabetes type
  Future<List<Map<String, dynamic>>> getEducationPlansByType(String diabetesType) async {
    QuerySnapshot snapshot = await _educationPlansCollection
        .where('diabetesType', isEqualTo: diabetesType)
        .where('isActive', isEqualTo: true)
        .get();

    return snapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      return {
        'id': doc.id,
        ...data,
      };
    }).toList();
  }

  // Assign education plan to user
  Future<void> assignEducationPlan(String userId, String planId) async {
    await _usersCollection.doc(userId).update({
      'assignedPlanId': planId,
    });
  }

  // ADMIN OPERATIONS

  // Create new content
  Future<String> createContent(ContentModel content) async {
    DocumentReference contentRef = await _contentCollection.add(content.toMap());
    return contentRef.id;
  }

  // Update existing content
  Future<void> updateContent(String contentId, ContentModel content) async {
    await _contentCollection.doc(contentId).update(content.toMap());
  }

  // Create new quiz
  Future<String> createQuiz(QuizModel quiz) async {
    DocumentReference quizRef = await _quizCollection.add(quiz.toMap());
    return quizRef.id;
  }

  // Update existing quiz
  Future<void> updateQuiz(String quizId, QuizModel quiz) async {
    await _quizCollection.doc(quizId).update(quiz.toMap());
  }

  // Get all users (for admin)
  Future<List<UserModel>> getAllUsers() async {
    QuerySnapshot snapshot = await _usersCollection.get();
    return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
  }

  // Get analytics data (for admin)
  Future<Map<String, dynamic>> getAnalyticsData() async {
    // User stats
    QuerySnapshot userSnapshot = await _usersCollection.get();
    int totalUsers = userSnapshot.docs.length;

    // Content stats
    QuerySnapshot contentSnapshot = await _contentCollection.get();
    int totalContent = contentSnapshot.docs.length;

    // Progress stats
    QuerySnapshot progressSnapshot = await _progressCollection
        .where('isCompleted', isEqualTo: true)
        .get();
    int completedLessons = progressSnapshot.docs.length;

    // Calculate completion rate - number of completed lessons divided by
    // (total number of users * total number of content)
    double completionRate = totalUsers > 0 && totalContent > 0
        ? completedLessons / (totalUsers * totalContent)
        : 0;

    // Quiz stats
    Map<String, dynamic> quizStats = await _getQuizStats();

    return {
      'totalUsers': totalUsers,
      'totalContent': totalContent,
      'completedLessons': completedLessons,
      'completionRate': completionRate,
      'quizStats': quizStats,
    };
  }

  // Helper method to get quiz statistics
  Future<Map<String, dynamic>> _getQuizStats() async {
    QuerySnapshot progressSnapshot = await _progressCollection.get();

    int totalAttempts = 0;
    int totalPassed = 0;

    for (var doc in progressSnapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      if (data['metadata'] != null &&
          data['metadata']['quizAttempted'] == true) {
        totalAttempts++;

        if (data['metadata']['quizPassed'] == true) {
          totalPassed++;
        }
      }
    }

    double passRate = totalAttempts > 0 ? totalPassed / totalAttempts : 0;

    return {
      'totalAttempts': totalAttempts,
      'totalPassed': totalPassed,
      'passRate': passRate,
    };
  }
}
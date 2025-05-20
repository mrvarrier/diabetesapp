// File: lib/data/services/database_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/constants.dart';
import '../models/achievement_model.dart';
import '../models/content_model.dart';
import '../models/progress_model.dart';
import '../models/quiz_model.dart';
import '../models/user_model.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections references
  CollectionReference get _usersCollection =>
      _firestore.collection(AppConstants.usersCollection);

  CollectionReference get _contentsCollection =>
      _firestore.collection(AppConstants.contentsCollection);

  CollectionReference get _quizzesCollection =>
      _firestore.collection(AppConstants.quizzesCollection);

  CollectionReference get _progressCollection =>
      _firestore.collection(AppConstants.progressCollection);

  CollectionReference get _achievementsCollection =>
      _firestore.collection(AppConstants.achievementsCollection);

  CollectionReference get _plansCollection =>
      _firestore.collection(AppConstants.plansCollection);

  CollectionReference get _feedbackCollection =>
      _firestore.collection(AppConstants.feedbackCollection);

  // User methods
  Future<List<User>> getAllUsers() async {
    try {
      final querySnapshot = await _usersCollection.get();
      return querySnapshot.docs
          .map((doc) => User.fromFirestore(doc))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> getUserById(String userId) async {
    try {
      final docSnapshot = await _usersCollection.doc(userId).get();
      if (docSnapshot.exists) {
        return User.fromFirestore(docSnapshot);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Content methods
  Future<List<Content>> getAllContents() async {
    try {
      final querySnapshot = await _contentsCollection
          .orderBy('order', descending: false)
          .get();
      return querySnapshot.docs
          .map((doc) => Content.fromFirestore(doc))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Content>> getContentsByType(String contentType) async {
    try {
      final querySnapshot = await _contentsCollection
          .where('contentType', isEqualTo: contentType)
          .orderBy('order', descending: false)
          .get();
      return querySnapshot.docs
          .map((doc) => Content.fromFirestore(doc))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Content>> getContentsByRequirements({
    required String diabetesType,
    required String treatmentMethod,
  }) async {
    try {
      // Get content that either has no requirements or matches user's profile
      final querySnapshot = await _contentsCollection
          .where('isActive', isEqualTo: true)
          .orderBy('order', descending: false)
          .get();

      final contents = querySnapshot.docs
          .map((doc) => Content.fromFirestore(doc))
          .toList();

      // Filter contents that are applicable to the user
      return contents.where((content) =>
          content.isApplicableTo(diabetesType, treatmentMethod)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<Content?> getContentById(String contentId) async {
    try {
      final docSnapshot = await _contentsCollection.doc(contentId).get();
      if (docSnapshot.exists) {
        return Content.fromFirestore(docSnapshot);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<Content> addContent(Content content) async {
    try {
      final docRef = await _contentsCollection.add(content.toJson());
      final newContent = content.copyWith(id: docRef.id);
      return newContent;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateContent(Content content) async {
    try {
      await _contentsCollection.doc(content.id).update(content.toJson());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteContent(String contentId) async {
    try {
      await _contentsCollection.doc(contentId).delete();
    } catch (e) {
      rethrow;
    }
  }

  // Quiz methods
  Future<List<Quiz>> getAllQuizzes() async {
    try {
      final querySnapshot = await _quizzesCollection
          .where('isActive', isEqualTo: true)
          .get();
      return querySnapshot.docs
          .map((doc) => Quiz.fromFirestore(doc))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<Quiz?> getQuizById(String quizId) async {
    try {
      final docSnapshot = await _quizzesCollection.doc(quizId).get();
      if (docSnapshot.exists) {
        return Quiz.fromFirestore(docSnapshot);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<Quiz?> getQuizByContentId(String contentId) async {
    try {
      final querySnapshot = await _quizzesCollection
          .where('contentId', isEqualTo: contentId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        return Quiz.fromFirestore(querySnapshot.docs.first);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<Quiz> addQuiz(Quiz quiz) async {
    try {
      final docRef = await _quizzesCollection.add(quiz.toJson());
      final newQuiz = quiz.copyWith(id: docRef.id);
      return newQuiz;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateQuiz(Quiz quiz) async {
    try {
      await _quizzesCollection.doc(quiz.id).update(quiz.toJson());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteQuiz(String quizId) async {
    try {
      await _quizzesCollection.doc(quizId).delete();
    } catch (e) {
      rethrow;
    }
  }

  // Progress methods
  Future<List<Progress>> getUserProgress(String userId) async {
    try {
      final querySnapshot = await _progressCollection
          .where('userId', isEqualTo: userId)
          .get();
      return querySnapshot.docs
          .map((doc) => Progress.fromFirestore(doc))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<Progress?> getContentProgress(String userId, String contentId) async {
    try {
      final querySnapshot = await _progressCollection
          .where('userId', isEqualTo: userId)
          .where('contentId', isEqualTo: contentId)
          .limit(1)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        return Progress.fromFirestore(querySnapshot.docs.first);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<Progress> createProgress(Progress progress) async {
    try {
      final docRef = await _progressCollection.add(progress.toJson());
      final newProgress = progress.copyWith(id: docRef.id);
      return newProgress;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateProgress(Progress progress) async {
    try {
      await _progressCollection.doc(progress.id).update(progress.toJson());
    } catch (e) {
      rethrow;
    }
  }

  // Check if user has streaks
  Future<bool> hasCompletedLessonToday(String userId) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final querySnapshot = await _progressCollection
          .where('userId', isEqualTo: userId)
          .where('isCompleted', isEqualTo: true)
          .get();

      for (final doc in querySnapshot.docs) {
        final progress = Progress.fromFirestore(doc);

        if (progress.completedAt != null) {
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
    } catch (e) {
      rethrow;
    }
  }

  // Achievement methods
  Future<List<Achievement>> getUserAchievements(String userId) async {
    try {
      final querySnapshot = await _achievementsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('awardedAt', descending: true)
          .get();
      return querySnapshot.docs
          .map((doc) => Achievement.fromFirestore(doc))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<Achievement?> getUserAchievementByType(String userId, String achievementType) async {
    try {
      final querySnapshot = await _achievementsCollection
          .where('userId', isEqualTo: userId)
          .where('achievementType', isEqualTo: achievementType)
          .limit(1)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        return Achievement.fromFirestore(querySnapshot.docs.first);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<Achievement> addAchievement(Achievement achievement) async {
    try {
      // Check if achievement already exists
      final existingAchievement = await getUserAchievementByType(
          achievement.userId,
          achievement.achievementType
      );

      if (existingAchievement != null) {
        return existingAchievement;
      }

      final docRef = await _achievementsCollection.add(achievement.toJson());
      final newAchievement = achievement.copyWith(id: docRef.id);

      // Update user's total points
      await _usersCollection.doc(achievement.userId).update({
        'totalPoints': FieldValue.increment(achievement.pointsAwarded),
      });

      return newAchievement;
    } catch (e) {
      rethrow;
    }
  }

  // Feedback methods
  Future<void> addFeedback(
      String userId,
      String contentId,
      int rating,
      String? comment
      ) async {
    try {
      await _feedbackCollection.add({
        'userId': userId,
        'contentId': contentId,
        'rating': rating,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Analytics methods
  Future<Map<String, int>> getUserStatistics(String userId) async {
    try {
      // Get user data
      final userDoc = await _usersCollection.doc(userId).get();
      final userData = User.fromFirestore(userDoc);

      // Get completed lessons count
      final progressSnapshot = await _progressCollection
          .where('userId', isEqualTo: userId)
          .where('isCompleted', isEqualTo: true)
          .get();

      // Get achievements count
      final achievementsSnapshot = await _achievementsCollection
          .where('userId', isEqualTo: userId)
          .get();

      return {
        'totalPoints': userData.totalPoints,
        'completedLessons': progressSnapshot.docs.length,
        'achievements': achievementsSnapshot.docs.length,
        'currentStreak': userData.currentStreak,
        'longestStreak': userData.longestStreak,
      };
    } catch (e) {
      rethrow;
    }
  }

  // Check and update user streak
  Future<void> checkAndUpdateUserStreak(String userId) async {
    try {
      final userDoc = await _usersCollection.doc(userId).get();
      if (!userDoc.exists) return;

      final userData = User.fromFirestore(userDoc);
      final currentStreak = userData.currentStreak;

      // Get most recent completed lesson date
      final querySnapshot = await _progressCollection
          .where('userId', isEqualTo: userId)
          .where('isCompleted', isEqualTo: true)
          .orderBy('completedAt', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return;

      final mostRecentProgress = Progress.fromFirestore(querySnapshot.docs.first);
      if (mostRecentProgress.completedAt == null) return;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));

      final lastCompleted = DateTime(
        mostRecentProgress.completedAt!.year,
        mostRecentProgress.completedAt!.month,
        mostRecentProgress.completedAt!.day,
      );

      // If completed today, streak is maintained or increased
      if (lastCompleted.isAtSameMomentAs(today)) {
        // Streak already updated today, no action needed
        return;
      }
      // If completed yesterday, increase streak
      else if (lastCompleted.isAtSameMomentAs(yesterday)) {
        final newStreak = currentStreak + 1;
        await _usersCollection.doc(userId).update({
          'currentStreak': newStreak,
          'longestStreak': newStreak > userData.longestStreak ? newStreak : userData.longestStreak,
        });

        // Check for streak achievements
        if (newStreak == 3) {
          final achievement = Achievement.create(
            userId: userId,
            achievementType: AppConstants.achievement3DayStreak,
          );
          await addAchievement(achievement);
        } else if (newStreak == 7) {
          final achievement = Achievement.create(
            userId: userId,
            achievementType: AppConstants.achievement7DayStreak,
          );
          await addAchievement(achievement);
        }
      }
      // If gap is more than 1 day, reset streak
      else {
        await _usersCollection.doc(userId).update({
          'currentStreak': 0,
        });
      }
    } catch (e) {
      rethrow;
    }
  }
}
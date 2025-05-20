import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'database_service.dart';
import 'analytics_service.dart';
import '../models/feedback_model.dart';

class FeedbackService {
  final DatabaseService _databaseService;
  final AnalyticsService _analyticsService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Constructor
  FeedbackService({
    required DatabaseService databaseService,
    required AnalyticsService analyticsService,
  }) :
        _databaseService = databaseService,
        _analyticsService = analyticsService;

  // Submit feedback for content
  Future<bool> submitContentFeedback({
    required String contentId,
    required int rating,
    String? comment,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return false;
      }

      // Submit feedback to database
      await _databaseService.submitFeedback(
        userId: user.uid,
        contentId: contentId,
        rating: rating,
        comment: comment,
        metadata: {
          'deviceInfo': await _getDeviceInfo(),
          'timestamp': FieldValue.serverTimestamp(),
        },
      );

      // Log feedback event in analytics
      await _analyticsService.logProvideFeedback(
        contentId,
        rating,
        comment != null && comment.isNotEmpty,
      );

      return true;
    } catch (e) {
      print('Error submitting feedback: $e');
      return false;
    }
  }

  // Get feedback statistics for content
  Future<Map<String, dynamic>> getContentFeedbackStats(String contentId) async {
    return await _databaseService.getContentFeedbackStats(contentId);
  }

  // Submit app feedback
  Future<bool> submitAppFeedback({
    required String category,
    required String feedback,
    int? rating,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      // Create feedback document
      await _firestore.collection('app_feedback').add({
        'userId': user?.uid ?? 'anonymous',
        'category': category,
        'feedback': feedback,
        'rating': rating,
        'createdAt': FieldValue.serverTimestamp(),
        'deviceInfo': await _getDeviceInfo(),
      });

      return true;
    } catch (e) {
      print('Error submitting app feedback: $e');
      return false;
    }
  }

  // Submit bug report
  Future<bool> submitBugReport({
    required String description,
    required String stepsToReproduce,
    String? screenshot,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      // Create bug report document
      await _firestore.collection('bug_reports').add({
        'userId': user?.uid ?? 'anonymous',
        'description': description,
        'stepsToReproduce': stepsToReproduce,
        'screenshot': screenshot,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'new',
        'deviceInfo': await _getDeviceInfo(),
      });

      return true;
    } catch (e) {
      print('Error submitting bug report: $e');
      return false;
    }
  }

  // Submit feature request
  Future<bool> submitFeatureRequest({
    required String title,
    required String description,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      // Create feature request document
      await _firestore.collection('feature_requests').add({
        'userId': user?.uid ?? 'anonymous',
        'title': title,
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'new',
        'votes': 1,
        'voters': [user?.uid ?? 'anonymous'],
      });

      return true;
    } catch (e) {
      print('Error submitting feature request: $e');
      return false;
    }
  }

  // Get user's feedback history
  Future<List<FeedbackModel>> getUserFeedbackHistory() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return [];
      }

      // Query feedback collection for user's feedback
      QuerySnapshot snapshot = await _firestore.collection('feedback')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => FeedbackModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting user feedback history: $e');
      return [];
    }
  }

  // Vote for a feature request
  Future<bool> voteForFeatureRequest(String requestId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return false;
      }

      // Get feature request document
      DocumentSnapshot doc = await _firestore.collection('feature_requests').doc(requestId).get();

      if (!doc.exists) {
        return false;
      }

      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      List<String> voters = List<String>.from(data['voters'] ?? []);

      // Check if user already voted
      if (voters.contains(user.uid)) {
        return false;
      }

      // Add user to voters and increment vote count
      voters.add(user.uid);

      await _firestore.collection('feature_requests').doc(requestId).update({
        'votes': FieldValue.increment(1),
        'voters': voters,
      });

      return true;
    } catch (e) {
      print('Error voting for feature request: $e');
      return false;
    }
  }

  // Helper method to get device info
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    // In a real app, use device_info_plus package to get detailed device info
    // For MVP, we'll return basic platform info
    return {
      'platform': 'flutter',
      'appVersion': '1.0.0',
    };
  }
}
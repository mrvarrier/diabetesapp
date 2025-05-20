import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream to track the authentication state
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get the current user
  User? get currentUser => _auth.currentUser;

  // Get user UID
  String? get uid => _auth.currentUser?.uid;

  // Check if user is logged in
  bool get isLoggedIn => _auth.currentUser != null;

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update last active timestamp
      await _firestore.collection('users').doc(result.user!.uid).update({
        'lastActive': FieldValue.serverTimestamp(),
      });

      notifyListeners();
      return result;
    } catch (e) {
      rethrow;
    }
  }

  // Register with email and password
  Future<UserCredential> registerWithEmailAndPassword(
      String email,
      String password,
      String fullName,
      int age,
      String gender,
      String diabetesType,
      String treatmentMethod
      ) async {
    try {
      // Create user account
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document in Firestore
      await _createUserDocument(
        result.user!.uid,
        email,
        fullName,
        age,
        gender,
        diabetesType,
        treatmentMethod,
      );

      // Assign default education plan based on diabetes type
      await _assignDefaultEducationPlan(result.user!.uid, diabetesType);

      notifyListeners();
      return result;
    } catch (e) {
      rethrow;
    }
  }

  // Create a user document in Firestore
  Future<void> _createUserDocument(
      String uid,
      String email,
      String fullName,
      int age,
      String gender,
      String diabetesType,
      String treatmentMethod,
      ) async {
    await _firestore.collection('users').doc(uid).set({
      'email': email,
      'fullName': fullName,
      'age': age,
      'gender': gender,
      'diabetesType': diabetesType,
      'treatmentMethod': treatmentMethod,
      'points': 0,
      'streakDays': 0,
      'lastActive': FieldValue.serverTimestamp(),
      'onboardingComplete': false,
      'completedLessons': [],
      'unlockedAchievements': [],
      'notificationSettings': {
        'dailyReminder': true,
        'achievements': true,
        'newContent': true,
      },
      'isDarkModeEnabled': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Assign default education plan based on diabetes type
  Future<void> _assignDefaultEducationPlan(String uid, String diabetesType) async {
    // Get the default plan ID for this diabetes type
    QuerySnapshot planSnapshot = await _firestore
        .collection('education_plans')
        .where('diabetesType', isEqualTo: diabetesType)
        .where('isDefault', isEqualTo: true)
        .limit(1)
        .get();

    if (planSnapshot.docs.isNotEmpty) {
      String planId = planSnapshot.docs.first.id;

      // Assign plan to user
      await _firestore.collection('users').doc(uid).update({
        'assignedPlanId': planId,
      });
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Update user profile
  Future<void> updateProfile({
    String? fullName,
    int? age,
    String? gender,
    String? diabetesType,
    String? treatmentMethod,
    Map<String, dynamic>? notificationSettings,
    bool? isDarkModeEnabled,
  }) async {
    if (_auth.currentUser == null) {
      throw Exception('User not logged in');
    }

    Map<String, dynamic> updateData = {};

    if (fullName != null) updateData['fullName'] = fullName;
    if (age != null) updateData['age'] = age;
    if (gender != null) updateData['gender'] = gender;
    if (diabetesType != null) updateData['diabetesType'] = diabetesType;
    if (treatmentMethod != null) updateData['treatmentMethod'] = treatmentMethod;
    if (notificationSettings != null) updateData['notificationSettings'] = notificationSettings;
    if (isDarkModeEnabled != null) updateData['isDarkModeEnabled'] = isDarkModeEnabled;

    await _firestore.collection('users').doc(_auth.currentUser!.uid).update(updateData);
    notifyListeners();
  }

  // Get current user data
  Future<UserModel?> getCurrentUserData() async {
    if (_auth.currentUser == null) {
      return null;
    }

    DocumentSnapshot doc = await _firestore.collection('users').doc(_auth.currentUser!.uid).get();

    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }

    return null;
  }

  // Check if onboarding is complete
  Future<bool> isOnboardingComplete() async {
    if (_auth.currentUser == null) {
      return false;
    }

    DocumentSnapshot doc = await _firestore.collection('users').doc(_auth.currentUser!.uid).get();

    if (doc.exists) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      return data['onboardingComplete'] ?? false;
    }

    return false;
  }

  // Mark onboarding as complete
  Future<void> completeOnboarding() async {
    if (_auth.currentUser == null) {
      throw Exception('User not logged in');
    }

    await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
      'onboardingComplete': true,
    });

    notifyListeners();
  }

  // Delete account
  Future<void> deleteAccount() async {
    if (_auth.currentUser == null) {
      throw Exception('User not logged in');
    }

    String uid = _auth.currentUser!.uid;

    // Delete user document
    await _firestore.collection('users').doc(uid).delete();

    // Delete related progress data
    QuerySnapshot progressSnapshot = await _firestore
        .collection('progress')
        .where('userId', isEqualTo: uid)
        .get();

    for (var doc in progressSnapshot.docs) {
      await doc.reference.delete();
    }

    // Delete related feedback
    QuerySnapshot feedbackSnapshot = await _firestore
        .collection('feedback')
        .where('userId', isEqualTo: uid)
        .get();

    for (var doc in feedbackSnapshot.docs) {
      await doc.reference.delete();
    }

    // Delete auth account
    await _auth.currentUser!.delete();

    notifyListeners();
  }

  // Check if user is an admin
  Future<bool> isAdmin() async {
    if (_auth.currentUser == null) {
      return false;
    }

    DocumentSnapshot doc = await _firestore.collection('admins').doc(_auth.currentUser!.uid).get();
    return doc.exists;
  }

  // Update user streak
  Future<void> updateStreak() async {
    if (_auth.currentUser == null) {
      return;
    }

    DocumentSnapshot userDoc = await _firestore.collection('users').doc(_auth.currentUser!.uid).get();

    if (userDoc.exists) {
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      DateTime? lastActive = (userData['lastActive'] as Timestamp?)?.toDate();
      int currentStreak = userData['streakDays'] ?? 0;

      // Check if the last active date was yesterday
      if (lastActive != null) {
        DateTime now = DateTime.now();
        DateTime yesterday = DateTime(now.year, now.month, now.day - 1);
        DateTime lastActiveDate = DateTime(
          lastActive.year,
          lastActive.month,
          lastActive.day,
        );

        if (lastActiveDate.isAtSameMomentAs(yesterday)) {
          // Increase streak
          await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
            'streakDays': currentStreak + 1,
            'lastActive': FieldValue.serverTimestamp(),
          });
        } else if (!lastActiveDate.isAtSameMomentAs(DateTime(now.year, now.month, now.day))) {
          // Reset streak if not active today or yesterday
          await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
            'streakDays': 1, // Reset to 1 for today
            'lastActive': FieldValue.serverTimestamp(),
          });
        }
      }
    }

    notifyListeners();
  }
}
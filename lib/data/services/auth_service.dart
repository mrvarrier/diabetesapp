// File: lib/data/services/auth_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/constants.dart';
import '../models/user_model.dart' as app_models;

class AuthService {
  final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user ID
  String? get currentUserId => _firebaseAuth.currentUser?.uid;

  // Check if user is logged in
  bool get isLoggedIn => _firebaseAuth.currentUser != null;

  // Sign in with email and password
  Future<app_models.User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        // Update last login time
        await _firestore.collection(AppConstants.usersCollection).doc(user.uid).update({
          'lastLoginAt': FieldValue.serverTimestamp(),
        });

        // Save user ID to SharedPreferences for offline use
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.userIdKey, user.uid);

        // Get user data from Firestore
        return await getUserById(user.uid);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Register with email and password
  Future<app_models.User?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required int age,
    required String gender,
    required String diabetesType,
    required String treatmentMethod,
  }) async {
    try {
      // Create user in Firebase Auth
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        // Create user data in Firestore
        final userData = app_models.User(
          id: user.uid,
          name: name,
          email: email,
          age: age,
          gender: gender,
          diabetesType: diabetesType,
          treatmentMethod: treatmentMethod,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );

        await _firestore.collection(AppConstants.usersCollection).doc(user.uid).set(userData.toJson());

        // Save user ID to SharedPreferences for offline use
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.userIdKey, user.uid);

        return userData;
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();

      // Clear user ID from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.userIdKey);
    } catch (e) {
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  // Get user by ID from Firestore
  Future<app_models.User?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection(AppConstants.usersCollection).doc(userId).get();
      if (doc.exists) {
        return app_models.User.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Get current user from Firestore
  Future<app_models.User?> getCurrentUser() async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser != null) {
        return await getUserById(currentUser.uid);
      }

      // Try to get user ID from SharedPreferences for offline use
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(AppConstants.userIdKey);
      if (userId != null) {
        return await getUserById(userId);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // Update user profile
  Future<app_models.User?> updateUserProfile({
    required String userId,
    String? name,
    int? age,
    String? gender,
    String? diabetesType,
    String? treatmentMethod,
    String? profileImageUrl,
  }) async {
    try {
      final userRef = _firestore.collection(AppConstants.usersCollection).doc(userId);

      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (age != null) updateData['age'] = age;
      if (gender != null) updateData['gender'] = gender;
      if (diabetesType != null) updateData['diabetesType'] = diabetesType;
      if (treatmentMethod != null) updateData['treatmentMethod'] = treatmentMethod;
      if (profileImageUrl != null) updateData['profileImageUrl'] = profileImageUrl;

      await userRef.update(updateData);

      return await getUserById(userId);
    } catch (e) {
      rethrow;
    }
  }

  // Complete onboarding
  Future<void> completeOnboarding(String userId) async {
    try {
      await _firestore.collection(AppConstants.usersCollection).doc(userId).update({
        'isOnboardingCompleted': true,
      });
    } catch (e) {
      rethrow;
    }
  }

  // Update user points
  Future<void> updateUserPoints(String userId, int pointsToAdd) async {
    try {
      await _firestore.collection(AppConstants.usersCollection).doc(userId).update({
        'totalPoints': FieldValue.increment(pointsToAdd),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Update user streak
  Future<void> updateUserStreak(String userId, int newStreak) async {
    try {
      final userRef = _firestore.collection(AppConstants.usersCollection).doc(userId);
      final userDoc = await userRef.get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        final longestStreak = data['longestStreak'] ?? 0;

        // Update longest streak if current streak is higher
        if (newStreak > longestStreak) {
          await userRef.update({
            'currentStreak': newStreak,
            'longestStreak': newStreak,
          });
        } else {
          await userRef.update({
            'currentStreak': newStreak,
          });
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  // Reset user streak
  Future<void> resetUserStreak(String userId) async {
    try {
      await _firestore.collection(AppConstants.usersCollection).doc(userId).update({
        'currentStreak': 0,
      });
    } catch (e) {
      rethrow;
    }
  }
}
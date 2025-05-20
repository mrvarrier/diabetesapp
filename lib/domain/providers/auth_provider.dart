// File: lib/domain/providers/auth_provider.dart

import 'package:flutter/foundation.dart';
import '../../data/models/user_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/local_storage_service.dart';

enum AuthStatus {
  uninitialized,
  authenticated,
  unauthenticated,
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final LocalStorageService _localStorageService = LocalStorageService();

  AuthStatus _status = AuthStatus.uninitialized;
  User? _user;
  String? _error;
  bool _isLoading = false;

  // Getters
  AuthStatus get status => _status;
  User? get user => _user;
  String? get error => _error;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  String? get userId => _user?.id;

  // Constructor
  AuthProvider() {
    // Automatically check auth state when created
    _checkAuthState();
  }

  // Check current authentication state
  Future<void> _checkAuthState() async {
    _setLoading(true);

    try {
      // First try to get current Firebase user
      final user = await _authService.getCurrentUser();

      if (user != null) {
        _user = user;
        _status = AuthStatus.authenticated;
      } else {
        // If Firebase auth fails, try to get user from local storage
        final localUser = await _localStorageService.getCurrentUser();

        if (localUser != null) {
          _user = localUser;
          _status = AuthStatus.authenticated;
        } else {
          _status = AuthStatus.unauthenticated;
        }
      }
    } catch (e) {
      _error = e.toString();
      _status = AuthStatus.unauthenticated;
    } finally {
      _setLoading(false);
    }
  }

  // Sign in with email and password
  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    _error = null;

    try {
      final user = await _authService.signInWithEmailAndPassword(
        email,
        password,
      );

      if (user != null) {
        _user = user;
        _status = AuthStatus.authenticated;

        // Save user to local storage for offline access
        await _localStorageService.saveCurrentUser(user);

        return true;
      } else {
        _error = 'Failed to sign in. Please check your credentials.';
        return false;
      }
    } catch (e) {
      _error = _getFirebaseAuthErrorMessage(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Register with email and password
  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required int age,
    required String gender,
    required String diabetesType,
    required String treatmentMethod,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final user = await _authService.registerWithEmailAndPassword(
        email: email,
        password: password,
        name: name,
        age: age,
        gender: gender,
        diabetesType: diabetesType,
        treatmentMethod: treatmentMethod,
      );

      if (user != null) {
        _user = user;
        _status = AuthStatus.authenticated;

        // Save user to local storage for offline access
        await _localStorageService.saveCurrentUser(user);

        return true;
      } else {
        _error = 'Failed to register. Please try again.';
        return false;
      }
    } catch (e) {
      _error = _getFirebaseAuthErrorMessage(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sign out
  Future<void> signOut() async {
    _setLoading(true);

    try {
      await _authService.signOut();

      // Clear local user data but preserve cached content
      final prefs = await _localStorageService.getCurrentUser();

      _user = null;
      _status = AuthStatus.unauthenticated;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _error = null;

    try {
      await _authService.resetPassword(email);
      return true;
    } catch (e) {
      _error = _getFirebaseAuthErrorMessage(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update user profile
  Future<bool> updateUserProfile({
    String? name,
    int? age,
    String? gender,
    String? diabetesType,
    String? treatmentMethod,
    String? profileImageUrl,
  }) async {
    if (_user == null) return false;

    _setLoading(true);
    _error = null;

    try {
      final updatedUser = await _authService.updateUserProfile(
        userId: _user!.id,
        name: name,
        age: age,
        gender: gender,
        diabetesType: diabetesType,
        treatmentMethod: treatmentMethod,
        profileImageUrl: profileImageUrl,
      );

      if (updatedUser != null) {
        _user = updatedUser;

        // Update user in local storage
        await _localStorageService.saveCurrentUser(updatedUser);

        notifyListeners();
        return true;
      } else {
        _error = 'Failed to update profile. Please try again.';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Complete onboarding
  Future<bool> completeOnboarding() async {
    if (_user == null) return false;

    try {
      await _authService.completeOnboarding(_user!.id);

      // Update local user
      _user = _user!.copyWith(isOnboardingCompleted: true);

      // Update user in local storage
      await _localStorageService.saveCurrentUser(_user!);

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  // Refresh user data
  Future<void> refreshUserData() async {
    if (_user == null) return;

    try {
      final updatedUser = await _authService.getUserById(_user!.id);
      if (updatedUser != null) {
        _user = updatedUser;

        // Update user in local storage
        await _localStorageService.saveCurrentUser(updatedUser);

        notifyListeners();
      }
    } catch (e) {
      // Silently handle error
    }
  }

  // Update streak info after completing lesson
  Future<void> updateStreakAfterCompletion() async {
    if (_user == null) return;

    try {
      // Try to update streak on server if possible
      await _authService.updateUserStreak(_user!.id, _user!.currentStreak + 1);

      // Refresh user data to get updated streak
      await refreshUserData();
    } catch (e) {
      // Handle offline case - update locally
      _user = _user!.copyWith(
        currentStreak: _user!.currentStreak + 1,
        longestStreak: _user!.currentStreak + 1 > _user!.longestStreak
            ? _user!.currentStreak + 1
            : _user!.longestStreak,
      );

      // Update user in local storage
      await _localStorageService.saveCurrentUser(_user!);

      notifyListeners();
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Convert Firebase auth error messages to user-friendly messages
  String _getFirebaseAuthErrorMessage(String errorMessage) {
    if (errorMessage.contains('user-not-found')) {
      return 'No user found with this email address.';
    } else if (errorMessage.contains('wrong-password')) {
      return 'Incorrect password. Please try again.';
    } else if (errorMessage.contains('email-already-in-use')) {
      return 'This email is already registered. Please use a different email or try logging in.';
    } else if (errorMessage.contains('weak-password')) {
      return 'The password is too weak. Please use a stronger password.';
    } else if (errorMessage.contains('invalid-email')) {
      return 'Invalid email format. Please enter a valid email address.';
    } else if (errorMessage.contains('network-request-failed')) {
      return 'Network error. Please check your connection and try again.';
    } else {
      return 'An error occurred. Please try again later.';
    }
  }
}
// File: lib/data/services/sync_service.dart

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../config/constants.dart';
import '../models/content_model.dart';
import '../models/progress_model.dart';
import '../models/achievement_model.dart';
import '../models/quiz_model.dart';
import '../models/user_model.dart';
import 'database_service.dart';
import 'local_storage_service.dart';

class SyncService {
  final DatabaseService _databaseService;
  final LocalStorageService _localStorageService;

  StreamSubscription? _connectivitySubscription;
  bool _isSyncing = false;
  Timer? _syncTimer;

  SyncService({
    required DatabaseService databaseService,
    required LocalStorageService localStorageService,
  }) : _databaseService = databaseService,
        _localStorageService = localStorageService;

  // Initialize sync service
  void init() {
    // Listen for connectivity changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        // When internet is available, attempt to sync
        syncData();
      }
    });

    // Set up periodic sync
    _setupPeriodicSync();
  }

  // Set up periodic sync
  void _setupPeriodicSync() {
    _syncTimer?.cancel();

    // Attempt to sync every hour when the app is running
    _syncTimer = Timer.periodic(const Duration(hours: 1), (timer) async {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        syncData();
      }
    });
  }

  // Sync data between local storage and Firestore
  Future<bool> syncData() async {
    if (_isSyncing) return false;

    _isSyncing = true;
    bool success = false;

    try {
      // Get current user
      final currentUser = await _localStorageService.getCurrentUser();
      if (currentUser == null) {
        _isSyncing = false;
        return false;
      }

      // Get last sync time
      final lastSyncTime = await _localStorageService.getLastSyncTime();

      // Sync user data
      await _syncUserData(currentUser);

      // Sync content (download new content)
      await _syncContent();

      // Sync quizzes (download new quizzes)
      await _syncQuizzes();

      // Sync progress (upload local progress)
      await _syncProgress(currentUser.id, lastSyncTime);

      // Sync achievements (upload local achievements)
      await _syncAchievements(currentUser.id, lastSyncTime);

      // Update last sync time
      await _localStorageService.updateLastSyncTime();

      success = true;
    } catch (e) {
      success = false;
      // Error handling would be implemented here
    } finally {
      _isSyncing = false;
    }

    return success;
  }

  // Sync user data
  Future<void> _syncUserData(User localUser) async {
    try {
      // Get user data from Firestore
      final remoteUser = await _databaseService.getUserById(localUser.id);

      if (remoteUser != null) {
        // Save updated user data to local storage
        await _localStorageService.saveCurrentUser(remoteUser);
      } else {
        // If user doesn't exist in Firestore, it might have been deleted
        // Handle this case accordingly
      }
    } catch (e) {
      // Error handling
      rethrow;
    }
  }

  // Sync content
  Future<void> _syncContent() async {
    try {
      // Get all content from Firestore
      final remoteContents = await _databaseService.getAllContents();

      // Get all content from local storage
      final localContents = await _localStorageService.getAllContents();

      // Map of local contents by ID for easy lookup
      final localContentMap = {for (var content in localContents) content.id: content};

      // Identify new or updated content
      final contentsToUpdate = <Content>[];

      for (final remoteContent in remoteContents) {
        final localContent = localContentMap[remoteContent.id];

        if (localContent == null) {
          // New content
          contentsToUpdate.add(remoteContent);
        } else if (remoteContent.updatedAt.isAfter(localContent.updatedAt)) {
          // Updated content
          contentsToUpdate.add(remoteContent);
        }
      }

      // Save new or updated content to local storage
      if (contentsToUpdate.isNotEmpty) {
        await _localStorageService.saveContents(contentsToUpdate);
      }
    } catch (e) {
      // Error handling
      rethrow;
    }
  }

  // Sync quizzes
  Future<void> _syncQuizzes() async {
    try {
      // Get all quizzes from Firestore
      final remoteQuizzes = await _databaseService.getAllQuizzes();

      // Save quizzes to local storage
      await _localStorageService.saveQuizzes(remoteQuizzes);
    } catch (e) {
      // Error handling
      rethrow;
    }
  }

  // Sync progress
  Future<void> _syncProgress(String userId, DateTime? lastSyncTime) async {
    try {
      // Get all local progress
      final localProgressList = await _localStorageService.getAllProgress();

      // Filter progress that belongs to the current user
      final userProgressList = localProgressList
          .where((progress) => progress.userId == userId)
          .toList();

      // Upload local progress to Firestore
      for (final localProgress in userProgressList) {
        // Check if progress needs to be synced (new or updated since last sync)
        if (lastSyncTime == null ||
            localProgress.lastInteractionAt.isAfter(lastSyncTime)) {

          // Check if progress exists in Firestore
          final remoteProgress = await _databaseService.getContentProgress(
              userId,
              localProgress.contentId
          );

          if (remoteProgress == null) {
            // Create new progress in Firestore
            await _databaseService.createProgress(localProgress);
          } else {
            // Compare local and remote progress
            if (localProgress.lastInteractionAt.isAfter(remoteProgress.lastInteractionAt)) {
              // Local progress is newer, update Firestore
              await _databaseService.updateProgress(localProgress);
            } else {
              // Remote progress is newer, update local storage
              await _localStorageService.saveProgress(remoteProgress);
            }
          }
        }
      }

      // Get all remote progress
      final remoteProgressList = await _databaseService.getUserProgress(userId);

      // Map of local progress by content ID for easy lookup
      final localProgressMap = {
        for (var progress in userProgressList) progress.contentId: progress
      };

      // Identify new remote progress not in local storage
      for (final remoteProgress in remoteProgressList) {
        if (!localProgressMap.containsKey(remoteProgress.contentId)) {
          // Save to local storage
          await _localStorageService.saveProgress(remoteProgress);
        }
      }
    } catch (e) {
      // Error handling
      rethrow;
    }
  }

  // Sync achievements
  Future<void> _syncAchievements(String userId, DateTime? lastSyncTime) async {
    try {
      // Get remote achievements
      final remoteAchievements = await _databaseService.getUserAchievements(userId);

      // Save to local storage
      await _localStorageService.saveAchievements(remoteAchievements);
    } catch (e) {
      // Error handling
      rethrow;
    }
  }

  // Force a full sync
  Future<bool> forceSyncData() async {
    // Cancel any existing sync timer
    _syncTimer?.cancel();

    // Force a sync
    final result = await syncData();

    // Restart periodic sync
    _setupPeriodicSync();

    return result;
  }

  // Check if user has a valid streak
  Future<bool> checkAndUpdateStreak(String userId) async {
    try {
      // Check if internet is available
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        // If online, check and update streak on Firestore
        await _databaseService.checkAndUpdateUserStreak(userId);

        // Sync user data to get updated streak
        final remoteUser = await _databaseService.getUserById(userId);
        if (remoteUser != null) {
          await _localStorageService.saveCurrentUser(remoteUser);
        }

        return true;
      } else {
        // If offline, can't update streak properly
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // Dispose
  void dispose() {
    _connectivitySubscription?.cancel();
    _syncTimer?.cancel();
  }
}
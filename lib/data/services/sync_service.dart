import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'database_service.dart';
import 'local_storage_service.dart';
import 'notification_service.dart';
import '../models/progress_model.dart';
import '../constants/string_constants.dart';

class SyncService {
  final DatabaseService _databaseService;
  final LocalStorageService _localStorageService;
  final NotificationService? _notificationService;

  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  bool _isSyncing = false;

  SyncService({
    required DatabaseService databaseService,
    required LocalStorageService localStorageService,
    NotificationService? notificationService,
  }) :
        _databaseService = databaseService,
        _localStorageService = localStorageService,
        _notificationService = notificationService {
    // Initialize connectivity listener
    _initConnectivityListener();
  }

  // Initialize connectivity listener
  void _initConnectivityListener() {
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen(_handleConnectivityChange);
  }

  // Handle connectivity changes
  void _handleConnectivityChange(ConnectivityResult result) async {
    if (result != ConnectivityResult.none) {
      // Connection restored, sync data
      await syncData();
    } else {
      // Connection lost, enable offline mode
      await _localStorageService.setOfflineMode(true);
    }
  }

  // Dispose resources
  void dispose() {
    _connectivitySubscription.cancel();
  }

  // Sync data between local storage and Firestore
  Future<bool> syncData() async {
    // Check if user is logged in
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return false;
    }

    // Check if already syncing
    if (_isSyncing) {
      return false;
    }

    _isSyncing = true;
    bool success = false;

    try {
      // Notify user that sync is starting (optional)
      _notificationService?.createLocalNotification(
        title: 'Syncing Data',
        body: StringConstants.syncInProgress,
      );

      // 1. Sync user data
      await _syncUserData(user.uid);

      // 2. Sync progress data
      await _syncProgressData(user.uid);

      // 3. Download needed content
      await _syncContentData(user.uid);

      // 4. Update last sync timestamp
      await _localStorageService.saveLastSyncTimestamp();

      // Set offline mode to false
      await _localStorageService.setOfflineMode(false);

      // Notify user that sync is complete
      _notificationService?.createLocalNotification(
        title: 'Sync Complete',
        body: StringConstants.syncComplete,
      );

      success = true;
    } catch (e) {
      // Handle sync errors
      print('Sync error: $e');

      // Notify user of sync failure
      _notificationService?.createLocalNotification(
        title: 'Sync Failed',
        body: StringConstants.syncFailed,
      );

      success = false;
    } finally {
      _isSyncing = false;
    }

    return success;
  }

  // Sync user data
  Future<void> _syncUserData(String uid) async {
    // Get user data from Firestore
    final firebaseUser = await _databaseService.getUser(uid);

    // Get local user data
    final localUser = await _localStorageService.getUserData();

    if (firebaseUser != null) {
      // Update local storage with Firebase data
      await _localStorageService.saveUserData(firebaseUser);
    } else if (localUser != null) {
      // If no Firebase data but we have local data, upload it
      // This would be rare but could happen if user created account offline
      // For MVP, we'll skip this case
    }
  }

  // Sync progress data
  Future<void> _syncProgressData(String uid) async {
    // Get local progress data
    final localProgress = await _localStorageService.getUserProgress(uid);

    // For each local progress entry:
    for (ProgressModel progress in localProgress) {
      // Check if it's completed
      if (progress.isCompleted) {
        // Check if it exists in Firebase
        final firebaseProgress = await _databaseService.getUserContentProgress(
          uid,
          progress.contentId,
        );

        if (firebaseProgress == null || !firebaseProgress.isCompleted) {
          // Upload to Firebase if not exists or not completed
          if (firebaseProgress == null) {
            // Create new progress entry
            String progressId = await _databaseService.startContentProgress(
              uid,
              progress.contentId,
            );

            // Complete it with points earned
            await _databaseService.completeContentProgress(
              progressId,
              progress.pointsEarned,
            );

            // Also update user's completed lessons and points
            await _databaseService.addCompletedLesson(uid, progress.contentId);
            await _databaseService.updateUserPoints(uid, progress.pointsEarned);
          } else {
            // Update existing entry
            await _databaseService.completeContentProgress(
              firebaseProgress.id,
              progress.pointsEarned,
            );

            // Update user's completed lessons and points
            await _databaseService.addCompletedLesson(uid, progress.contentId);
            await _databaseService.updateUserPoints(uid, progress.pointsEarned);
          }
        }
      }
    }

    // Get all Firebase progress to update local cache
    final firebaseProgress = await _databaseService.getUserProgress(uid);

    // Update local cache with all progress from Firebase
    for (ProgressModel progress in firebaseProgress) {
      await _localStorageService.saveProgress(progress);
    }
  }

  // Sync content data
  Future<void> _syncContentData(String uid) async {
    // Get user's assigned plan
    final user = await _databaseService.getUser(uid);
    if (user == null || user.assignedPlanId.isEmpty) {
      return;
    }

    // Get all modules for the plan
    final modules = await _databaseService.getModules(user.assignedPlanId);

    // For each module, get all content
    for (var module in modules) {
      final String moduleId = module['id'];

      // Get module content from Firebase
      final moduleContent = await _databaseService.getModuleContent(moduleId);

      // Cache all content locally
      for (var content in moduleContent) {
        // Check if we have it locally already
        final localContent = await _localStorageService.getContent(content.id);

        // If not in local storage or if it's been updated, save it
        if (localContent == null ||
            localContent.updatedAt.isBefore(content.updatedAt)) {
          await _localStorageService.saveContent(content);

          // Also get and cache the quiz for this content
          final quiz = await _databaseService.getContentQuiz(content.id);
          if (quiz != null) {
            await _localStorageService.saveQuiz(quiz);
          }
        }
      }
    }
  }

  // Check if sync is needed
  Future<bool> isSyncNeeded() async {
    // If device is offline, we can't sync
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      return false;
    }

    // Check if it's been more than 24 hours since last sync
    return _localStorageService.isSyncNeeded();
  }

  // Force sync data
  Future<bool> forceSyncData() async {
    // Check connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      // Notify user they're offline
      _notificationService?.createLocalNotification(
        title: StringConstants.offlineMode,
        body: StringConstants.internetRequired,
      );
      return false;
    }

    // If online, force a sync
    return await syncData();
  }

  // Handle conflict resolution (for advanced synchronization)
  Future<void> _resolveConflicts(String entityType, String id, Map<String, dynamic> localData, Map<String, dynamic> remoteData) async {
    // Simple conflict resolution strategy for MVP:
    // - For user data: prefer remote data for everything except completed lessons (merge those)
    // - For progress data: if both local and remote are completed, keep the one with more points
    // - For content data: always prefer remote data

    if (entityType == 'user') {
      // Merge completed lessons
      List<String> localCompletedLessons = List<String>.from(localData['completedLessons'] ?? []);
      List<String> remoteCompletedLessons = List<String>.from(remoteData['completedLessons'] ?? []);

      // Combine lists and remove duplicates
      Set<String> mergedLessons = Set<String>.from([...localCompletedLessons, ...remoteCompletedLessons]);

      // Use remote data but with merged completed lessons
      remoteData['completedLessons'] = mergedLessons.toList();

      // Save merged user data
      await _databaseService.updateUserPoints(id, 0); // Dummy update to save the data
    } else if (entityType == 'progress') {
      bool localCompleted = localData['isCompleted'] ?? false;
      bool remoteCompleted = remoteData['isCompleted'] ?? false;

      if (localCompleted && remoteCompleted) {
        // Both completed, keep the one with more points
        int localPoints = localData['pointsEarned'] ?? 0;
        int remotePoints = remoteData['pointsEarned'] ?? 0;

        if (localPoints > remotePoints) {
          // Update remote with local points
          await _databaseService.completeContentProgress(id, localPoints);
        }
      } else if (localCompleted && !remoteCompleted) {
        // Local completed but remote not, update remote
        int localPoints = localData['pointsEarned'] ?? 0;
        await _databaseService.completeContentProgress(id, localPoints);
      }
    }
    // For content, we always use remote data, so no special handling needed
  }
}
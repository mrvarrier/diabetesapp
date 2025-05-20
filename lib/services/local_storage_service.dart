import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/content_model.dart';
import '../models/quiz_model.dart';
import '../models/progress_model.dart';
import '../models/user_model.dart';

class LocalStorageService {
  static SharedPreferences? _preferences;
  static Box<Map>? _contentBox;
  static Box<Map>? _quizBox;
  static Box<Map>? _progressBox;
  static Box<Map>? _userBox;

  // Keys for SharedPreferences
  static const String USER_KEY = 'user_data';
  static const String AUTH_TOKEN_KEY = 'auth_token';
  static const String LAST_SYNC_KEY = 'last_sync_timestamp';
  static const String APP_SETTINGS_KEY = 'app_settings';
  static const String OFFLINE_MODE_KEY = 'offline_mode';

  // Hive box names
  static const String CONTENT_BOX = 'content_box';
  static const String QUIZ_BOX = 'quiz_box';
  static const String PROGRESS_BOX = 'progress_box';
  static const String USER_BOX = 'user_box';

  // Initialize SharedPreferences and Hive
  static Future<LocalStorageService> init() async {
    _preferences = await SharedPreferences.getInstance();

    // Initialize Hive
    await Hive.initFlutter();

    // Open boxes
    _contentBox = await Hive.openBox<Map>(CONTENT_BOX);
    _quizBox = await Hive.openBox<Map>(QUIZ_BOX);
    _progressBox = await Hive.openBox<Map>(PROGRESS_BOX);
    _userBox = await Hive.openBox<Map>(USER_BOX);

    return LocalStorageService();
  }

  // USER DATA METHODS

  // Save user data locally
  Future<void> saveUserData(UserModel user) async {
    // Convert user model to a map
    final userData = user.toMap();

    // Add the user ID
    userData['uid'] = user.uid;

    // Store in SharedPreferences for quick access
    await _preferences?.setString(USER_KEY, jsonEncode(userData));

    // Store in Hive for more complex operations
    await _userBox?.put(user.uid, userData);
  }

  // Get user data
  Future<UserModel?> getUserData() async {
    // Try to get from SharedPreferences first (faster)
    final userJson = _preferences?.getString(USER_KEY);

    if (userJson != null) {
      try {
        final Map<String, dynamic> userData = jsonDecode(userJson);
        return _createUserModelFromMap(userData);
      } catch (e) {
        // If parsing fails, try from Hive
        return _getUserFromHive();
      }
    } else {
      // Try from Hive if not in SharedPreferences
      return _getUserFromHive();
    }
  }

  // Helper to get user from Hive
  Future<UserModel?> _getUserFromHive() async {
    if (_userBox == null || _userBox!.isEmpty) {
      return null;
    }

    // Get the first user (there should only be one)
    final userData = _userBox!.values.first;

    if (userData is Map) {
      return _createUserModelFromMap(Map<String, dynamic>.from(userData));
    }

    return null;
  }

  // Helper to create UserModel from map
  UserModel _createUserModelFromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      age: map['age'] ?? 0,
      gender: map['gender'] ?? '',
      diabetesType: map['diabetesType'] ?? '',
      treatmentMethod: map['treatmentMethod'] ?? '',
      points: map['points'] ?? 0,
      streakDays: map['streakDays'] ?? 0,
      lastActive: map['lastActive'] != null
          ? DateTime.parse(map['lastActive'])
          : DateTime.now(),
      onboardingComplete: map['onboardingComplete'] ?? false,
      completedLessons: List<String>.from(map['completedLessons'] ?? []),
      unlockedAchievements: List<String>.from(map['unlockedAchievements'] ?? []),
      assignedPlanId: map['assignedPlanId'] ?? '',
      notificationSettings: map['notificationSettings'] ?? {},
      isDarkModeEnabled: map['isDarkModeEnabled'] ?? false,
    );
  }

  // Delete user data
  Future<void> deleteUserData() async {
    await _preferences?.remove(USER_KEY);
    await _userBox?.clear();
  }

  // Update user points locally
  Future<void> updateUserPoints(int points) async {
    final user = await getUserData();
    if (user != null) {
      final updatedUser = user.copyWith(points: user.points + points);
      await saveUserData(updatedUser);
    }
  }

  // CONTENT DATA METHODS

  // Save content data locally
  Future<void> saveContent(ContentModel content) async {
    // Convert content model to a map
    final contentData = content.toMap();

    // Add the content ID
    contentData['id'] = content.id;

    // Store in Hive
    await _contentBox?.put(content.id, contentData);
  }

  // Get content by ID
  Future<ContentModel?> getContent(String contentId) async {
    final contentData = _contentBox?.get(contentId);

    if (contentData != null) {
      return _createContentModelFromMap(Map<String, dynamic>.from(contentData));
    }

    return null;
  }

  // Get all content for a module
  Future<List<ContentModel>> getModuleContent(String moduleId) async {
    if (_contentBox == null) {
      return [];
    }

    // Filter content by module ID
    final List<ContentModel> moduleContents = [];

    for (var contentData in _contentBox!.values) {
      if (contentData is Map && contentData['moduleId'] == moduleId) {
        moduleContents.add(_createContentModelFromMap(Map<String, dynamic>.from(contentData)));
      }
    }

    // Sort by sequence number
    moduleContents.sort((a, b) => a.sequenceNumber.compareTo(b.sequenceNumber));

    return moduleContents;
  }

  // Helper to create ContentModel from map
  ContentModel _createContentModelFromMap(Map<String, dynamic> map) {
    return ContentModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      contentType: ContentType.values.firstWhere(
            (e) => e.toString() == 'ContentType.${map['contentType']}',
        orElse: () => ContentType.mixed,
      ),
      youtubeVideoId: map['youtubeVideoId'] ?? '',
      slideUrls: List<String>.from(map['slideUrls'] ?? []),
      slideContents: List<String>.from(map['slideContents'] ?? []),
      pointsValue: map['pointsValue'] ?? 0,
      moduleId: map['moduleId'] ?? '',
      sequenceNumber: map['sequenceNumber'] ?? 0,
      estimatedDuration: map['estimatedDuration'] ?? 0,
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : DateTime.now(),
      isDownloadable: map['isDownloadable'] ?? true,
      metadata: map['metadata'] ?? {},
    );
  }

  // QUIZ DATA METHODS

  // Save quiz data locally
  Future<void> saveQuiz(QuizModel quiz) async {
    // Convert quiz to a map
    final quizData = quiz.toMap();

    // Add the quiz ID
    quizData['id'] = quiz.id;

    // Store in Hive
    await _quizBox?.put(quiz.id, quizData);
  }

  // Get quiz by ID
  Future<QuizModel?> getQuiz(String quizId) async {
    final quizData = _quizBox?.get(quizId);

    if (quizData != null) {
      return _createQuizModelFromMap(Map<String, dynamic>.from(quizData));
    }

    return null;
  }

  // Get quiz for a specific content
  Future<QuizModel?> getContentQuiz(String contentId) async {
    if (_quizBox == null) {
      return null;
    }

    // Find quiz for specific content
    for (var quizData in _quizBox!.values) {
      if (quizData is Map && quizData['contentId'] == contentId) {
        return _createQuizModelFromMap(Map<String, dynamic>.from(quizData));
      }
    }

    return null;
  }

  // Helper to create QuizModel from map
  QuizModel _createQuizModelFromMap(Map<String, dynamic> map) {
    List<QuizQuestion> questions = [];

    if (map['questions'] != null && map['questions'] is List) {
      questions = (map['questions'] as List)
          .map((q) => QuizQuestion.fromMap(Map<String, dynamic>.from(q)))
          .toList();
    }

    return QuizModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      moduleId: map['moduleId'] ?? '',
      contentId: map['contentId'] ?? '',
      pointsValue: map['pointsValue'] ?? 0,
      passingScore: map['passingScore'] ?? 70,
      questions: questions,
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : DateTime.now(),
    );
  }

  // PROGRESS DATA METHODS

  // Save progress data locally
  Future<void> saveProgress(ProgressModel progress) async {
    // Convert progress to a map
    final progressData = progress.toMap();

    // Add the progress ID
    progressData['id'] = progress.id;

    // Store in Hive
    await _progressBox?.put(progress.id, progressData);
  }

  // Get progress by ID
  Future<ProgressModel?> getProgress(String progressId) async {
    final progressData = _progressBox?.get(progressId);

    if (progressData != null) {
      return _createProgressModelFromMap(Map<String, dynamic>.from(progressData));
    }

    return null;
  }

  // Get user progress for a specific content
  Future<ProgressModel?> getUserContentProgress(String userId, String contentId) async {
    if (_progressBox == null) {
      return null;
    }

    // Find progress for specific user and content
    for (var progressData in _progressBox!.values) {
      if (progressData is Map &&
          progressData['userId'] == userId &&
          progressData['contentId'] == contentId) {
        return _createProgressModelFromMap(Map<String, dynamic>.from(progressData));
      }
    }

    return null;
  }

  // Get all progress for a user
  Future<List<ProgressModel>> getUserProgress(String userId) async {
    if (_progressBox == null) {
      return [];
    }

    // Filter progress by user ID
    final List<ProgressModel> userProgress = [];

    for (var progressData in _progressBox!.values) {
      if (progressData is Map && progressData['userId'] == userId) {
        userProgress.add(_createProgressModelFromMap(Map<String, dynamic>.from(progressData)));
      }
    }

    return userProgress;
  }

  // Helper to create ProgressModel from map
  ProgressModel _createProgressModelFromMap(Map<String, dynamic> map) {
    return ProgressModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      contentId: map['contentId'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
      pointsEarned: map['pointsEarned'] ?? 0,
      startTime: map['startTime'] != null
          ? DateTime.parse(map['startTime'])
          : DateTime.now(),
      completionTime: map['completionTime'] != null
          ? DateTime.parse(map['completionTime'])
          : null,
      watchTimeSeconds: map['watchTimeSeconds'] ?? 0,
      metadata: map['metadata'] ?? {},
    );
  }

  // SYNC METHODS

  // Save last sync timestamp
  Future<void> saveLastSyncTimestamp() async {
    await _preferences?.setString(LAST_SYNC_KEY, DateTime.now().toIso8601String());
  }

  // Get last sync timestamp
  DateTime? getLastSyncTimestamp() {
    final timestampStr = _preferences?.getString(LAST_SYNC_KEY);
    if (timestampStr != null) {
      try {
        return DateTime.parse(timestampStr);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Check if sync is needed (more than 24 hours since last sync)
  bool isSyncNeeded() {
    final lastSync = getLastSyncTimestamp();
    if (lastSync == null) {
      return true;
    }

    final now = DateTime.now();
    return now.difference(lastSync).inHours > 24;
  }

  // APP SETTINGS METHODS

  // Save app settings
  Future<void> saveAppSettings(Map<String, dynamic> settings) async {
    await _preferences?.setString(APP_SETTINGS_KEY, jsonEncode(settings));
  }

  // Get app settings
  Map<String, dynamic> getAppSettings() {
    final settingsJson = _preferences?.getString(APP_SETTINGS_KEY);
    if (settingsJson != null) {
      try {
        return jsonDecode(settingsJson);
      } catch (e) {
        return {};
      }
    }
    return {};
  }

  // OFFLINE MODE METHODS

  // Set offline mode
  Future<void> setOfflineMode(bool enabled) async {
    await _preferences?.setBool(OFFLINE_MODE_KEY, enabled);
  }

  // Get offline mode
  bool isOfflineModeEnabled() {
    return _preferences?.getBool(OFFLINE_MODE_KEY) ?? false;
  }

  // Save auth token
  Future<void> saveAuthToken(String token) async {
    await _preferences?.setString(AUTH_TOKEN_KEY, token);
  }

  // Get auth token
  String? getAuthToken() {
    return _preferences?.getString(AUTH_TOKEN_KEY);
  }

  // Clear auth token
  Future<void> clearAuthToken() async {
    await _preferences?.remove(AUTH_TOKEN_KEY);
  }

  // STORAGE MANAGEMENT METHODS

  // Clear all cached data
  Future<void> clearAllCachedData() async {
    // Keep user data and auth token
    final userData = await getUserData();
    final authToken = getAuthToken();

    // Clear SharedPreferences
    await _preferences?.clear();

    // Clear Hive boxes
    await _contentBox?.clear();
    await _quizBox?.clear();
    await _progressBox?.clear();

    // Restore user data and auth token if they existed
    if (userData != null) {
      await saveUserData(userData);
    }

    if (authToken != null) {
      await saveAuthToken(authToken);
    }
  }

  // Get storage usage stats
  Future<Map<String, int>> getStorageStats() async {
    int contentCount = _contentBox?.length ?? 0;
    int quizCount = _quizBox?.length ?? 0;
    int progressCount = _progressBox?.length ?? 0;

    return {
      'contentCount': contentCount,
      'quizCount': quizCount,
      'progressCount': progressCount,
      'totalItems': contentCount + quizCount + progressCount,
    };
  }
}
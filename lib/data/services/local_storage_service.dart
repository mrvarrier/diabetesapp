// File: lib/data/services/local_storage_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/content_model.dart';
import '../models/progress_model.dart';
import '../models/user_model.dart';
import '../models/quiz_model.dart';
import '../models/achievement_model.dart';

class LocalStorageService {
  // Box names for Hive
  static const String _userBoxName = 'user_box';
  static const String _contentBoxName = 'content_box';
  static const String _progressBoxName = 'progress_box';
  static const String _quizBoxName = 'quiz_box';
  static const String _achievementBoxName = 'achievement_box';

  // Shared Preferences keys
  static const String _lastSyncKey = 'last_sync_time';
  static const String _userKey = 'current_user';
  static const String _cachePrefix = 'cache_';

  // Initialize Hive
  Future<void> init() async {
    await Hive.initFlutter();

    await Hive.openBox<String>(_userBoxName);
    await Hive.openBox<String>(_contentBoxName);
    await Hive.openBox<String>(_progressBoxName);
    await Hive.openBox<String>(_quizBoxName);
    await Hive.openBox<String>(_achievementBoxName);
  }

  // SharedPreferences instance
  Future<SharedPreferences> get _prefs async => await SharedPreferences.getInstance();

  // Hive boxes
  Box<String> get _userBox => Hive.box<String>(_userBoxName);
  Box<String> get _contentBox => Hive.box<String>(_contentBoxName);
  Box<String> get _progressBox => Hive.box<String>(_progressBoxName);
  Box<String> get _quizBox => Hive.box<String>(_quizBoxName);
  Box<String> get _achievementBox => Hive.box<String>(_achievementBoxName);

  // User methods
  Future<void> saveCurrentUser(User user) async {
    final userJson = json.encode(user.toJson());
    await _userBox.put(_userKey, userJson);

    // Also save to SharedPreferences for quicker access
    final prefs = await _prefs;
    await prefs.setString(_userKey, userJson);
  }

  Future<User?> getCurrentUser() async {
    try {
      // Try SharedPreferences first
      final prefs = await _prefs;
      final userJson = prefs.getString(_userKey) ?? _userBox.get(_userKey);

      if (userJson != null) {
        final Map<String, dynamic> userData = json.decode(userJson);
        return User.fromJson(userData, userData['id']);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // Content methods
  Future<void> saveContents(List<Content> contents) async {
    for (final content in contents) {
      final contentJson = json.encode(content.toJson());
      await _contentBox.put(content.id, contentJson);
    }
  }

  Future<List<Content>> getAllContents() async {
    try {
      final contents = <Content>[];

      for (final key in _contentBox.keys) {
        final contentJson = _contentBox.get(key);
        if (contentJson != null) {
          final Map<String, dynamic> contentData = json.decode(contentJson);
          contents.add(Content.fromJson(contentData, key));
        }
      }

      // Sort by order
      contents.sort((a, b) => a.order.compareTo(b.order));

      return contents;
    } catch (e) {
      return [];
    }
  }

  Future<Content?> getContentById(String contentId) async {
    try {
      final contentJson = _contentBox.get(contentId);
      if (contentJson != null) {
        final Map<String, dynamic> contentData = json.decode(contentJson);
        return Content.fromJson(contentData, contentId);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // Progress methods
  Future<void> saveProgress(Progress progress) async {
    final progressJson = json.encode(progress.toJson());
    await _progressBox.put(progress.id, progressJson);
  }

  Future<List<Progress>> getAllProgress() async {
    try {
      final progressList = <Progress>[];

      for (final key in _progressBox.keys) {
        final progressJson = _progressBox.get(key);
        if (progressJson != null) {
          final Map<String, dynamic> progressData = json.decode(progressJson);
          progressList.add(Progress.fromJson(progressData, key));
        }
      }

      return progressList;
    } catch (e) {
      return [];
    }
  }

  Future<Progress?> getProgressById(String progressId) async {
    try {
      final progressJson = _progressBox.get(progressId);
      if (progressJson != null) {
        final Map<String, dynamic> progressData = json.decode(progressJson);
        return Progress.fromJson(progressData, progressId);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Progress?> getContentProgress(String userId, String contentId) async {
    try {
      final progressId = '$userId-$contentId';
      return await getProgressById(progressId);
    } catch (e) {
      return null;
    }
  }

  // Quiz methods
  Future<void> saveQuizzes(List<Quiz> quizzes) async {
    for (final quiz in quizzes) {
      final quizJson = json.encode(quiz.toJson());
      await _quizBox.put(quiz.id, quizJson);
    }
  }

  Future<Quiz?> getQuizById(String quizId) async {
    try {
      final quizJson = _quizBox.get(quizId);
      if (quizJson != null) {
        final Map<String, dynamic> quizData = json.decode(quizJson);
        return Quiz.fromJson(quizData, quizId);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Quiz?> getQuizByContentId(String contentId) async {
    try {
      for (final key in _quizBox.keys) {
        final quizJson = _quizBox.get(key);
        if (quizJson != null) {
          final Map<String, dynamic> quizData = json.decode(quizJson);
          if (quizData['contentId'] == contentId) {
            return Quiz.fromJson(quizData, key);
          }
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // Achievement methods
  Future<void> saveAchievements(List<Achievement> achievements) async {
    for (final achievement in achievements) {
      final achievementJson = json.encode(achievement.toJson());
      await _achievementBox.put(achievement.id, achievementJson);
    }
  }

  Future<List<Achievement>> getUserAchievements(String userId) async {
    try {
      final achievements = <Achievement>[];

      for (final key in _achievementBox.keys) {
        final achievementJson = _achievementBox.get(key);
        if (achievementJson != null) {
          final Map<String, dynamic> achievementData = json.decode(achievementJson);
          if (achievementData['userId'] == userId) {
            achievements.add(Achievement.fromJson(achievementData, key));
          }
        }
      }

      // Sort by awarded date (descending)
      achievements.sort((a, b) => b.awardedAt.compareTo(a.awardedAt));

      return achievements;
    } catch (e) {
      return [];
    }
  }

  // Sync methods
  Future<DateTime?> getLastSyncTime() async {
    try {
      final prefs = await _prefs;
      final timestamp = prefs.getInt(_lastSyncKey);

      if (timestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> updateLastSyncTime() async {
    try {
      final prefs = await _prefs;
      await prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      // Ignore errors
    }
  }

  // Generic caching methods
  Future<void> saveToCache(String key, dynamic data, {Duration? expiry}) async {
    try {
      final prefs = await _prefs;
      final cacheData = {
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'expiry': expiry?.inMilliseconds,
      };

      await prefs.setString('$_cachePrefix$key', json.encode(cacheData));
    } catch (e) {
      // Ignore caching errors
    }
  }

  Future<dynamic> getFromCache(String key) async {
    try {
      final prefs = await _prefs;
      final cachedData = prefs.getString('$_cachePrefix$key');

      if (cachedData != null) {
        final data = json.decode(cachedData);
        final timestamp = data['timestamp'] as int;
        final expiry = data['expiry'] as int?;

        // Check if cache is expired
        if (expiry != null) {
          final now = DateTime.now().millisecondsSinceEpoch;
          if (now - timestamp > expiry) {
            // Cache expired
            return null;
          }
        }

        return data['data'];
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // Clear cache
  Future<void> clearCache() async {
    try {
      final prefs = await _prefs;
      final keysToRemove = <String>[];

      prefs.getKeys().forEach((key) {
        if (key.startsWith(_cachePrefix)) {
          keysToRemove.add(key);
        }
      });

      for (final key in keysToRemove) {
        await prefs.remove(key);
      }
    } catch (e) {
      // Ignore errors
    }
  }

  // Clear all data (for logout)
  Future<void> clearAllData() async {
    try {
      await _userBox.clear();
      await _contentBox.clear();
      await _progressBox.clear();
      await _quizBox.clear();
      await _achievementBox.clear();

      final prefs = await _prefs;
      await prefs.clear();
    } catch (e) {
      // Ignore errors
    }
  }
}
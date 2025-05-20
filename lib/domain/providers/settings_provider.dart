// File: lib/domain/providers/settings_provider.dart

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/constants.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/sync_service.dart';
import '../../data/services/local_storage_service.dart';
import '../../data/services/database_service.dart';

class SettingsProvider extends ChangeNotifier {
  final SharedPreferences _prefs;
  final NotificationService _notificationService = NotificationService();
  late SyncService _syncService;

  // Settings
  bool _isDarkMode;
  bool _isNotificationEnabled;
  int _reminderHour;
  int _reminderMinute;

  // Loading state
  bool _isLoading = false;
  String? _error;

  // Getters
  bool get isDarkMode => _isDarkMode;
  bool get isNotificationEnabled => _isNotificationEnabled;
  int get reminderHour => _reminderHour;
  int get reminderMinute => _reminderMinute;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Constructor
  SettingsProvider(this._prefs)
      : _isDarkMode = false,
        _isNotificationEnabled = true,
        _reminderHour = 9,
        _reminderMinute = 0 {
    // Initialize sync service
    _syncService = SyncService(
      databaseService: DatabaseService(),
      localStorageService: LocalStorageService(),
    );

    // Load settings
    _loadSettings();
  }

  // Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    _setLoading(true);

    try {
      // Load dark mode setting
      _isDarkMode = _prefs.getBool(AppConstants.isDarkModeKey) ?? false;

      // Load notification settings
      _isNotificationEnabled = await _notificationService.areNotificationsEnabled();

      // Load reminder time
      _reminderHour = _prefs.getInt('reminder_hour') ?? 9;
      _reminderMinute = _prefs.getInt('reminder_minute') ?? 0;

      // Initialize sync service
      _syncService.init();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Toggle dark mode
  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    await _prefs.setBool(AppConstants.isDarkModeKey, _isDarkMode);
    notifyListeners();
  }

  // Toggle notifications
  Future<void> toggleNotifications() async {
    _isNotificationEnabled = !_isNotificationEnabled;
    await _notificationService.setNotificationsEnabled(_isNotificationEnabled);

    if (_isNotificationEnabled) {
      // Schedule reminder
      await _scheduleReminder();
    }

    notifyListeners();
  }

  // Update reminder time
  Future<void> updateReminderTime(int hour, int minute) async {
    _reminderHour = hour;
    _reminderMinute = minute;

    // Save to preferences
    await _prefs.setInt('reminder_hour', hour);
    await _prefs.setInt('reminder_minute', minute);

    // Schedule reminder if enabled
    if (_isNotificationEnabled) {
      await _scheduleReminder();
    }

    notifyListeners();
  }

  // Schedule daily reminder
  Future<void> _scheduleReminder() async {
    await _notificationService.scheduleDailyReminder(
      hour: _reminderHour,
      minute: _reminderMinute,
    );
  }

  // Force sync data
  Future<bool> syncData() async {
    _setLoading(true);

    try {
      final result = await _syncService.forceSyncData();
      return result;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Clear all data (for logout)
  Future<void> clearAllData() async {
    _setLoading(true);

    try {
      // Dispose sync service
      _syncService.dispose();

      // Clear local storage
      final localStorageService = LocalStorageService();
      await localStorageService.clearAllData();

      // Cancel notifications
      await _notificationService.cancelAllNotifications();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  @override
  void dispose() {
    _syncService.dispose();
    super.dispose();
  }
}
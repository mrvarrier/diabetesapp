// File: lib/data/services/notification_service.dart

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_init;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/constants.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz_init.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
    DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels on Android
    await _createNotificationChannels();
  }

  Future<void> _createNotificationChannels() async {
    // Daily reminder channel
    const AndroidNotificationChannel dailyReminderChannel = AndroidNotificationChannel(
      AppConstants.dailyReminderChannelId,
      'Daily Reminders',
      description: 'Notifications to remind you of your daily learning goals',
      importance: Importance.high,
    );

    // Achievement channel
    const AndroidNotificationChannel achievementChannel = AndroidNotificationChannel(
      AppConstants.achievementChannelId,
      'Achievements',
      description: 'Notifications about your achievements and milestones',
      importance: Importance.high,
    );

    // Content update channel
    const AndroidNotificationChannel contentUpdateChannel = AndroidNotificationChannel(
      AppConstants.contentUpdateChannelId,
      'Content Updates',
      description: 'Notifications about new educational content',
      importance: Importance.defaultImportance,
    );

    // Create channels one by one
    final plugin = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    await plugin?.createNotificationChannel(dailyReminderChannel);
    await plugin?.createNotificationChannel(achievementChannel);
    await plugin?.createNotificationChannel(contentUpdateChannel);
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap
    // This would be implemented to navigate to the appropriate screen
    // based on the notification payload
  }

  // Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.notificationEnabledKey) ?? true;
  }

  // Enable or disable notifications
  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.notificationEnabledKey, enabled);

    if (!enabled) {
      // Cancel all scheduled notifications
      await _flutterLocalNotificationsPlugin.cancelAll();
    }
  }

  // Schedule daily reminder
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    String title = 'Time to Learn!',
    String body = 'Maintain your streak by completing a lesson today.',
  }) async {
    final isEnabled = await areNotificationsEnabled();
    if (!isEnabled) return;

    // Cancel previous reminder
    await _flutterLocalNotificationsPlugin.cancel(0);

    // Schedule new reminder
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If scheduled time is in the past, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      AppConstants.dailyReminderChannelId,
      'Daily Reminders',
      channelDescription: 'Notifications to remind you of your daily learning goals',
      importance: Importance.high,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      0, // ID for daily reminder
      title,
      body,
      scheduledDate,
      notificationDetails,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily at the same time
    );
  }

  // Send achievement notification
  Future<void> showAchievementNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    final isEnabled = await areNotificationsEnabled();
    if (!isEnabled) return;

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      AppConstants.achievementChannelId,
      'Achievements',
      channelDescription: 'Notifications about your achievements and milestones',
      importance: Importance.high,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      1, // ID for achievement notifications
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  // Send content update notification
  Future<void> showContentUpdateNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    final isEnabled = await areNotificationsEnabled();
    if (!isEnabled) return;

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      AppConstants.contentUpdateChannelId,
      'Content Updates',
      channelDescription: 'Notifications about new educational content',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      2, // ID for content update notifications
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  // Send streak notification
  Future<void> showStreakNotification({
    required int streakDays,
  }) async {
    final isEnabled = await areNotificationsEnabled();
    if (!isEnabled) return;

    String title = 'Streak Achievement!';
    String body = 'You\'ve maintained a learning streak of $streakDays days. Keep it up!';

    await showAchievementNotification(
      title: title,
      body: body,
      payload: 'streak_$streakDays',
    );
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }
}
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'database_service.dart';
import '../constants/string_constants.dart';
import 'dart:math';

class NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final DatabaseService _databaseService;

  // Notification channels
  static const String reminderChannelId = 'reminders';
  static const String achievementChannelId = 'achievements';
  static const String contentChannelId = 'content';
  static const String pointsChannelId = 'points';

  // Constructor
  NotificationService({required DatabaseService databaseService})
      : _databaseService = databaseService {
    _init();
  }

  // Initialize notifications
  Future<void> _init() async {
    // Initialize time zones
    tz_data.initializeTimeZones();

    // Initialize local notifications
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onSelectNotification,
    );

    // Set up notification channels for Android
    await _setupNotificationChannels();

    // Initialize Firebase Messaging
    await _initFirebaseMessaging();
  }

  // Setup notification channels for Android
  Future<void> _setupNotificationChannels() async {
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
      const AndroidNotificationChannel(
        reminderChannelId,
        'Daily Reminders',
        description: 'Daily reminders to maintain your streak',
        importance: Importance.high,
      ),
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
      const AndroidNotificationChannel(
        achievementChannelId,
        'Achievements',
        description: 'Notifications about unlocked achievements',
        importance: Importance.high,
      ),
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
      const AndroidNotificationChannel(
        contentChannelId,
        'New Content',
        description: 'Notifications about new educational content',
        importance: Importance.default_,
      ),
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
      const AndroidNotificationChannel(
        pointsChannelId,
        'Points & Rewards',
        description: 'Notifications about points earned and rewards',
        importance: Importance.default_,
      ),
    );
  }

  // Initialize Firebase Messaging
  Future<void> _initFirebaseMessaging() async {
    // Request permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // If message contains notification, show it
      if (message.notification != null) {
        _showFirebaseNotification(message);
      }

      // Process data message
      if (message.data.isNotEmpty) {
        _processDataMessage(message.data);
      }
    });

    // Handle when user taps on notification that opened the app
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpen);

    // Get FCM token
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      // Store the token in your database for targeted messages
      print('FCM Token: $token');
    }

    // Subscribe to topics
    await _firebaseMessaging.subscribeToTopic('all_users');
  }

  // Show notification from Firebase
  Future<void> _showFirebaseNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      await _flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _getChannelIdFromType(message.data['type'] ?? 'default'),
            'Channel Name',
            icon: android.smallIcon,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: message.data['route'],
      );
    }
  }

  // Process data message
  Future<void> _processDataMessage(Map<String, dynamic> data) async {
    // Create notification in Firestore
    if (data['userId'] != null) {
      await _databaseService.createNotification(
        userId: data['userId'],
        title: data['title'] ?? 'New Notification',
        body: data['body'] ?? '',
        notificationType: data['type'] ?? 'default',
        data: data,
        actionRoute: data['route'],
      );
    }
  }

  // Handle when notification is tapped
  Future<void> _handleNotificationOpen(RemoteMessage message) async {
    // Navigate based on the route specified in the message data
    if (message.data['route'] != null) {
      // Use your navigation service to navigate to the specified route
      print('Navigate to: ${message.data['route']}');
    }
  }

  // Handle notification selection
  void _onSelectNotification(NotificationResponse response) {
    String? payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      // Use your navigation service to navigate to the specified route
      print('Navigate to: $payload');
    }
  }

  // Get channel ID based on notification type
  String _getChannelIdFromType(String type) {
    switch (type) {
      case 'reminder':
        return reminderChannelId;
      case 'achievement':
        return achievementChannelId;
      case 'content':
        return contentChannelId;
      case 'points':
        return pointsChannelId;
      default:
        return reminderChannelId;
    }
  }

  // Create a local notification
  Future<void> createLocalNotification({
    required String title,
    required String body,
    String? payload,
    String channelId = reminderChannelId,
  }) async {
    await _flutterLocalNotificationsPlugin.show(
      Random().nextInt(1000000), // Random ID to avoid overwriting
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          'Channel Name',
          priority: Priority.high,
          importance: Importance.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }

  // Schedule a daily reminder notification
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    String title = StringConstants.dailyReminderTitle,
    String body = StringConstants.dailyReminderBody,
    String? payload,
  }) async {
    // Calculate next occurrence
    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If scheduled time is in the past, set it for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      0, // ID for daily reminder (fixed so we can cancel/update it)
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      NotificationDetails(
        android: const AndroidNotificationDetails(
          reminderChannelId,
          'Daily Reminders',
          priority: Priority.high,
          importance: Importance.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  // Cancel all scheduled notifications
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  // Cancel specific notification
  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  // Request notification permissions
  Future<bool> requestPermissions() async {
    // For iOS
    final bool? iosResult = await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    // For Android (Android 13+ requires runtime permission)
    final bool? androidResult = await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.requestPermission();

    return iosResult ?? androidResult ?? false;
  }

  // Schedule achievement notification when streak milestone is reached
  Future<void> scheduleStreakMilestoneNotification(int streakDays) async {
    String title = StringConstants.streakMilestoneTitle;
    String body;

    if (streakDays % 30 == 0) {
      body = 'Amazing! You\'ve maintained your learning streak for $streakDays days!';
    } else if (streakDays % 7 == 0) {
      body = 'Impressive! You\'ve kept your streak going for $streakDays days!';
    } else {
      return; // Only notify for weekly and monthly milestones
    }

    await createLocalNotification(
      title: title,
      body: body,
      payload: '/home',
      channelId: achievementChannelId,
    );
  }

  // Notify user of new content
  Future<void> notifyNewContent(String contentTitle) async {
    await createLocalNotification(
      title: StringConstants.newContentTitle,
      body: 'New content available: "$contentTitle"',
      payload: '/education-plan',
      channelId: contentChannelId,
    );
  }

  // Notify user of achievement unlocked
  Future<void> notifyAchievementUnlocked(String achievementTitle, int points) async {
    await createLocalNotification(
      title: StringConstants.achievementUnlockedTitle,
      body: 'You\'ve unlocked "$achievementTitle" and earned $points points!',
      payload: '/achievements',
      channelId: achievementChannelId,
    );
  }
}
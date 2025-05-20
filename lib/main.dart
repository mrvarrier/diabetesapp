import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'services/content_service.dart';
import 'services/points_service.dart';
import 'services/notification_service.dart';
import 'services/analytics_service.dart';
import 'services/local_storage_service.dart';
import 'services/sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize services
  final localStorageService = await LocalStorageService.init();
  final authService = AuthService();
  final databaseService = DatabaseService();
  final contentService = ContentService();
  final pointsService = PointsService();
  final notificationService = NotificationService();
  final analyticsService = AnalyticsService();
  final syncService = SyncService(
    databaseService: databaseService,
    localStorageService: localStorageService,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => authService),
        Provider(create: (_) => databaseService),
        Provider(create: (_) => contentService),
        ChangeNotifierProvider(create: (_) => pointsService),
        Provider(create: (_) => notificationService),
        Provider(create: (_) => analyticsService),
        Provider(create: (_) => localStorageService),
        Provider(create: (_) => syncService),
      ],
      child: const DiabetesEducationApp(),
    ),
  );
}
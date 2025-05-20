// File: lib/main.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'domain/providers/auth_provider.dart';
import 'domain/providers/content_provider.dart';
import 'domain/providers/progress_provider.dart';
import 'domain/providers/achievements_provider.dart';
import 'domain/providers/settings_provider.dart';
import 'domain/providers/quiz_provider.dart';
import 'data/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();

  // Set device orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize notification service
  await NotificationService().init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(sharedPreferences),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => ContentProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => QuizProvider(),
        ),
        ChangeNotifierProxyProvider<AuthProvider, ProgressProvider>(
          create: (_) => ProgressProvider(),
          update: (_, authProvider, progressProvider) =>
          progressProvider!..update(authProvider),
        ),
        ChangeNotifierProxyProvider<AuthProvider, AchievementsProvider>(
          create: (_) => AchievementsProvider(),
          update: (_, authProvider, achievementsProvider) =>
          achievementsProvider!..update(authProvider),
        ),
      ],
      child: const DiabetesEducationApp(),
    ),
  );
}
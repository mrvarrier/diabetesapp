// File: lib/app.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/constants.dart';
import 'config/routes.dart';
import 'config/theme.dart';
import 'domain/providers/settings_provider.dart';
import 'presentation/screens/auth/splash_screen.dart';

class DiabetesEducationApp extends StatelessWidget {
  const DiabetesEducationApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, _) {
        return MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme(),
          darkTheme: AppTheme.darkTheme(),
          themeMode: settingsProvider.isDarkMode
              ? ThemeMode.dark
              : ThemeMode.light,
          onGenerateRoute: AppRouter.generateRoute,
          initialRoute: AppConstants.splashRoute,
          home: const SplashScreen(),
        );
      },
    );
  }
}
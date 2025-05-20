import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'navigation/app_router.dart';
import 'services/auth_service.dart';
import 'constants/string_constants.dart';

class DiabetesEducationApp extends StatelessWidget {
  const DiabetesEducationApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return MaterialApp(
      title: StringConstants.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Respects system settings for light/dark mode
      debugShowCheckedModeBanner: false,
      onGenerateRoute: AppRouter.onGenerateRoute,
      navigatorKey: AppRouter.navigatorKey,
      home: StreamBuilder(
        stream: authService.authStateChanges,
        builder: (context, snapshot) {
          // Show splash screen while checking authentication state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen();
          }

          // If user is authenticated, show home page, otherwise show login
          final bool isAuthenticated = snapshot.hasData;
          if (isAuthenticated) {
            // Check if onboarding is needed for new users
            return FutureBuilder<bool>(
              future: authService.isOnboardingComplete(),
              builder: (context, onboardingSnapshot) {
                if (onboardingSnapshot.connectionState == ConnectionState.waiting) {
                  return const SplashScreen();
                }

                final bool onboardingComplete = onboardingSnapshot.data ?? false;
                if (onboardingComplete) {
                  return const HomePage();
                } else {
                  return const OnboardingScreen();
                }
              },
            );
          } else {
            return const LoginPage();
          }
        },
      ),
    );
  }
}

// Simple splash screen shown during initialization
class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/app_logo.png',
              width: 150,
              height: 150,
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(
              color: Colors.white,
            ),
            const SizedBox(height: 32),
            Text(
              StringConstants.appName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Forward declarations - these will be implemented in separate files
class LoginPage extends StatelessWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // This is just a placeholder - actual implementation will be in login_page.dart
    return const Scaffold();
  }
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // This is just a placeholder - actual implementation will be in home_page.dart
    return const Scaffold();
  }
}

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // This is just a placeholder - actual implementation will be in onboarding_screens.dart
    return const Scaffold();
  }
}
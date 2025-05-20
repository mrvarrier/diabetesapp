// File: lib/config/routes.dart

import 'package:flutter/material.dart';
import '../config/constants.dart';
import '../data/models/content_model.dart';
import '../presentation/screens/admin/admin_dashboard.dart';
import '../presentation/screens/admin/admin_login_page.dart';
import '../presentation/screens/admin/analytics_dashboard.dart';
import '../presentation/screens/admin/content_management_page.dart';
import '../presentation/screens/admin/plan_management_page.dart';
import '../presentation/screens/admin/quiz_management_page.dart';
import '../presentation/screens/admin/user_management_page.dart';
import '../presentation/screens/auth/login_page.dart';
import '../presentation/screens/auth/onboarding_screens.dart';
import '../presentation/screens/auth/register_page.dart';
import '../presentation/screens/auth/splash_screen.dart';
import '../presentation/screens/education/education_plan_page.dart';
import '../presentation/screens/education/feedback_form.dart';
import '../presentation/screens/education/lesson_completion_page.dart';
import '../presentation/screens/education/lesson_player.dart';
import '../presentation/screens/education/quiz_page.dart';
import '../presentation/screens/education/slide_viewer.dart';
import '../presentation/screens/gamification/achievements_page.dart';
import '../presentation/screens/gamification/leaderboard_page.dart';
import '../presentation/screens/home/home_page.dart';
import '../presentation/screens/home/settings_page.dart';
import '../presentation/screens/progress/progress_report_page.dart';
import '../presentation/screens/progress/stats_dashboard.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppConstants.splashRoute:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case AppConstants.loginRoute:
        return MaterialPageRoute(builder: (_) => const LoginPage());

      case AppConstants.registerRoute:
        return MaterialPageRoute(builder: (_) => const RegisterPage());

      case AppConstants.onboardingRoute:
        return MaterialPageRoute(builder: (_) => const OnboardingScreens());

      case AppConstants.homeRoute:
        return MaterialPageRoute(builder: (_) => const HomePage());

      case AppConstants.settingsRoute:
        return MaterialPageRoute(builder: (_) => const SettingsPage());

      case AppConstants.educationPlanRoute:
        return MaterialPageRoute(builder: (_) => const EducationPlanPage());

      case AppConstants.lessonPlayerRoute:
        final Content content = settings.arguments as Content;
        return MaterialPageRoute(builder: (_) => LessonPlayer(content: content));

      case AppConstants.slideViewerRoute:
        final Content content = settings.arguments as Content;
        return MaterialPageRoute(builder: (_) => SlideViewer(content: content));

      case AppConstants.quizRoute:
        final Map<String, dynamic> args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(builder: (_) => QuizPage(
          quizId: args['quizId'],
          lessonId: args['lessonId'],
        ));

      case AppConstants.lessonCompletionRoute:
        final Map<String, dynamic> args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(builder: (_) => LessonCompletionPage(
          lessonId: args['lessonId'],
          pointsEarned: args['pointsEarned'],
        ));

      case AppConstants.achievementsRoute:
        return MaterialPageRoute(builder: (_) => const AchievementsPage());

      case AppConstants.leaderboardRoute:
        return MaterialPageRoute(builder: (_) => const LeaderboardPage());

      case AppConstants.progressReportRoute:
        return MaterialPageRoute(builder: (_) => const ProgressReportPage());

      case AppConstants.statsDashboardRoute:
        return MaterialPageRoute(builder: (_) => const StatsDashboardPage());

      case AppConstants.feedbackFormRoute:
        final String contentId = settings.arguments as String;
        return MaterialPageRoute(builder: (_) => FeedbackForm(contentId: contentId));

      case AppConstants.adminLoginRoute:
        return MaterialPageRoute(builder: (_) => const AdminLoginPage());

      case AppConstants.adminDashboardRoute:
        return MaterialPageRoute(builder: (_) => const AdminDashboard());

      case AppConstants.contentManagementRoute:
        return MaterialPageRoute(builder: (_) => const ContentManagementPage());

      case AppConstants.quizManagementRoute:
        return MaterialPageRoute(builder: (_) => const QuizManagementPage());

      case AppConstants.planManagementRoute:
        return MaterialPageRoute(builder: (_) => const PlanManagementPage());

      case AppConstants.userManagementRoute:
        return MaterialPageRoute(builder: (_) => const UserManagementPage());

      case AppConstants.analyticsRoute:
        return MaterialPageRoute(builder: (_) => const AnalyticsDashboard());

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
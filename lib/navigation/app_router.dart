import 'package:flutter/material.dart';
import '../screens/authentication/login_page.dart';
import '../screens/authentication/register_page.dart';
import '../screens/authentication/forgot_password_page.dart';
import '../screens/authentication/onboarding_screens.dart';
import '../screens/home/home_page.dart';
import '../screens/education/education_plan_page.dart';
import '../screens/education/lesson_player.dart';
import '../screens/education/slide_viewer.dart';
import '../screens/education/quiz_page.dart';
import '../screens/education/lesson_completion_page.dart';
import '../screens/education/feedback_form.dart';
import '../screens/gamification/achievements_page.dart';
import '../screens/gamification/leaderboard_page.dart';
import '../screens/progress/progress_report_page.dart';
import '../screens/progress/stats_dashboard.dart';
import '../screens/settings/settings_page.dart';
import '../screens/admin/admin_login_page.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/admin/content_management_page.dart';
import '../screens/admin/quiz_management_page.dart';
import '../screens/admin/plan_management_page.dart';
import '../screens/admin/user_management_page.dart';
import '../screens/admin/analytics_dashboard.dart';
import '../models/content_model.dart';
import '../models/quiz_model.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
    // Authentication routes
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case '/register':
        return MaterialPageRoute(builder: (_) => const RegisterPage());
      case '/forgot-password':
        return MaterialPageRoute(builder: (_) => const ForgotPasswordPage());
      case '/onboarding':
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());

    // Main app routes
      case '/home':
        return MaterialPageRoute(builder: (_) => const HomePage());
      case '/settings':
        return MaterialPageRoute(builder: (_) => const SettingsPage());

    // Education content routes
      case '/education-plan':
        return MaterialPageRoute(builder: (_) => const EducationPlanPage());
      case '/lesson-player':
        final ContentModel content = settings.arguments as ContentModel;
        return MaterialPageRoute(builder: (_) => LessonPlayer(content: content));
      case '/slide-viewer':
        final ContentModel content = settings.arguments as ContentModel;
        return MaterialPageRoute(builder: (_) => SlideViewer(content: content));
      case '/quiz':
        final QuizModel quiz = settings.arguments as QuizModel;
        return MaterialPageRoute(builder: (_) => QuizPage(quiz: quiz));
      case '/lesson-completion':
        final Map<String, dynamic> args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => LessonCompletionPage(
            lessonId: args['lessonId'],
            pointsEarned: args['pointsEarned'],
            achievementsUnlocked: args['achievementsUnlocked'],
          ),
        );
      case '/feedback-form':
        final String contentId = settings.arguments as String;
        return MaterialPageRoute(builder: (_) => FeedbackForm(contentId: contentId));

    // Gamification routes
      case '/achievements':
        return MaterialPageRoute(builder: (_) => const AchievementsPage());
      case '/leaderboard':
        return MaterialPageRoute(builder: (_) => const LeaderboardPage());

    // Progress tracking routes
      case '/progress-report':
        return MaterialPageRoute(builder: (_) => const ProgressReportPage());
      case '/stats-dashboard':
        return MaterialPageRoute(builder: (_) => const StatsDashboard());

    // Admin routes
      case '/admin-login':
        return MaterialPageRoute(builder: (_) => const AdminLoginPage());
      case '/admin-dashboard':
        return MaterialPageRoute(builder: (_) => const AdminDashboard());
      case '/admin-content':
        return MaterialPageRoute(builder: (_) => const ContentManagementPage());
      case '/admin-quiz':
        return MaterialPageRoute(builder: (_) => const QuizManagementPage());
      case '/admin-plan':
        return MaterialPageRoute(builder: (_) => const PlanManagementPage());
      case '/admin-users':
        return MaterialPageRoute(builder: (_) => const UserManagementPage());
      case '/admin-analytics':
        return MaterialPageRoute(builder: (_) => const AnalyticsDashboard());

    // Default route in case of an unknown route name
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

  // Helper methods for easy navigation
  static void navigateTo(String routeName, {Object? arguments}) {
    navigatorKey.currentState?.pushNamed(routeName, arguments: arguments);
  }

  static void navigateToAndRemoveUntil(String routeName, {Object? arguments}) {
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      routeName,
          (route) => false,
      arguments: arguments,
    );
  }

  static void goBack() {
    navigatorKey.currentState?.pop();
  }
}
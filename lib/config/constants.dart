// File: lib/config/constants.dart

class AppConstants {
  // App Information
  static const String appName = "DiabetesEdu";
  static const String appVersion = "1.0.0";

  // Firebase Collections
  static const String usersCollection = "users";
  static const String contentsCollection = "contents";
  static const String quizzesCollection = "quizzes";
  static const String progressCollection = "progress";
  static const String achievementsCollection = "achievements";
  static const String feedbackCollection = "feedback";
  static const String plansCollection = "plans";

  // Storage Paths
  static const String slidesStoragePath = "slides";
  static const String profileImagesPath = "profile_images";

  // Shared Preferences Keys
  static const String userIdKey = "user_id";
  static const String userTokenKey = "user_token";
  static const String isDarkModeKey = "is_dark_mode";
  static const String lastSyncTimeKey = "last_sync_time";
  static const String cachedContentKey = "cached_content";
  static const String userProgressKey = "user_progress";
  static const String notificationEnabledKey = "notification_enabled";

  // Default Values
  static const int defaultPointsPerLesson = 10;
  static const int defaultPointsPerQuizQuestion = 5;
  static const int defaultStreakThreshold = 1; // Days
  static const int minVideoWatchPercentage = 80; // Percentage of video that must be watched

  // Notification Channels
  static const String dailyReminderChannelId = "daily_reminder";
  static const String achievementChannelId = "achievement";
  static const String contentUpdateChannelId = "content_update";

  // Timeouts
  static const int apiTimeoutSeconds = 30;
  static const int syncIntervalHours = 24;
  static const Duration cacheDuration = Duration(days: 7);

  // YouTube API
  static const String youtubeApiBaseUrl = "https://www.googleapis.com/youtube/v3";

  // Routes
  static const String splashRoute = "/";
  static const String loginRoute = "/login";
  static const String registerRoute = "/register";
  static const String onboardingRoute = "/onboarding";
  static const String homeRoute = "/home";
  static const String settingsRoute = "/settings";
  static const String educationPlanRoute = "/education-plan";
  static const String lessonPlayerRoute = "/lesson-player";
  static const String slideViewerRoute = "/slide-viewer";
  static const String quizRoute = "/quiz";
  static const String lessonCompletionRoute = "/lesson-completion";
  static const String achievementsRoute = "/achievements";
  static const String leaderboardRoute = "/leaderboard";
  static const String progressReportRoute = "/progress-report";
  static const String statsDashboardRoute = "/stats-dashboard";
  static const String feedbackFormRoute = "/feedback-form";
  static const String adminLoginRoute = "/admin-login";
  static const String adminDashboardRoute = "/admin-dashboard";
  static const String contentManagementRoute = "/content-management";
  static const String quizManagementRoute = "/quiz-management";
  static const String planManagementRoute = "/plan-management";
  static const String userManagementRoute = "/user-management";
  static const String analyticsRoute = "/analytics";

  // Error Messages
  static const String generalErrorMessage = "Something went wrong. Please try again.";
  static const String connectionErrorMessage = "No internet connection. Some features may be limited.";
  static const String authenticationErrorMessage = "Authentication failed. Please check your credentials.";
  static const String videoLoadingErrorMessage = "Failed to load video content. Please check your connection.";
  static const String syncErrorMessage = "Failed to sync your progress. Will try again later.";

  // Achievement Types
  static const String achievementFirstLesson = "first_lesson";
  static const String achievement100Points = "points_100";
  static const String achievement500Points = "points_500";
  static const String achievement1000Points = "points_1000";
  static const String achievementPerfectQuiz = "perfect_quiz";
  static const String achievement3DayStreak = "streak_3_days";
  static const String achievement7DayStreak = "streak_7_days";
  static const String achievementCompletePlan = "complete_plan";

  // User Types
  static const String userTypePatient = "patient";
  static const String userTypeAdmin = "admin";

  // Diabetes Types
  static const String diabetesType1 = "type1";
  static const String diabetesType2 = "type2";
  static const String diabetesGestational = "gestational";
  static const String diabetesPre = "prediabetes";

  // Treatment Methods
  static const String treatmentInsulin = "insulin";
  static const String treatmentPump = "pump";
  static const String treatmentMedication = "medication";
  static const String treatmentLifestyle = "lifestyle";

  // Content Types
  static const String contentTypeVideo = "video";
  static const String contentTypeSlide = "slide";
  static const String contentTypeQuiz = "quiz";

  // Quiz Question Types
  static const String questionTypeMultipleChoice = "multiple_choice";
  static const String questionTypeTrueFalse = "true_false";
  static const String questionTypeMatching = "matching";
}
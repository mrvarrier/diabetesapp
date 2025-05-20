import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/points_service.dart';
import '../../services/analytics_service.dart';
import '../../constants/string_constants.dart';
import '../../navigation/app_router.dart';
import '../../models/user_model.dart';
import '../../models/content_model.dart';
import '../widgets/loading_indicator.dart';
import 'daily_streak_card.dart';
import 'points_card.dart';
import 'upcoming_lesson_card.dart';
import 'continue_lesson_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<UserModel?> _userFuture;
  late Future<List<ContentModel>> _upcomingLessonsFuture;
  late Future<ContentModel?> _currentLessonFuture;

  @override
  void initState() {
    super.initState();
    _loadUserData();

    // Log screen view
    final analyticsService = Provider.of<AnalyticsService>(context, listen: false);
    analyticsService.logFeatureUse('home_screen_view');
  }

  void _loadUserData() {
    final authService = Provider.of<AuthService>(context, listen: false);
    _userFuture = authService.getCurrentUserData();

    final databaseService = Provider.of<DatabaseService>(context, listen: false);
    _upcomingLessonsFuture = _getUpcomingLessons(databaseService);
    _currentLessonFuture = _getCurrentLesson(databaseService);

    // Update user streak if needed
    authService.updateStreak();

    // Load points data
    final pointsService = Provider.of<PointsService>(context, listen: false);
    pointsService.loadUserPoints();
  }

  Future<List<ContentModel>> _getUpcomingLessons(DatabaseService databaseService) async {
    final user = await _userFuture;
    if (user == null || user.assignedPlanId.isEmpty) {
      return [];
    }

    // Get modules for the plan
    final modules = await databaseService.getModules(user.assignedPlanId);
    if (modules.isEmpty) {
      return [];
    }

    // Get content for each module
    List<ContentModel> allContent = [];
    for (var module in modules) {
      final moduleContent = await databaseService.getModuleContent(module['id']);
      allContent.addAll(moduleContent);
    }

    // Filter out completed lessons
    final upcomingLessons = allContent.where((content) =>
    !user.completedLessons.contains(content.id)
    ).toList();

    // Sort by sequence number
    upcomingLessons.sort((a, b) =>
        a.sequenceNumber.compareTo(b.sequenceNumber)
    );

    // Limit to 5 upcoming lessons
    return upcomingLessons.take(5).toList();
  }

  Future<ContentModel?> _getCurrentLesson(DatabaseService databaseService) async {
    final user = await _userFuture;
    if (user == null || user.assignedPlanId.isEmpty) {
      return null;
    }

    // Get progress data to find lessons in progress
    final progressList = await databaseService.getUserProgress(user.uid);

    // Filter for incomplete lessons
    final inProgressList = progressList.where((progress) =>
    !progress.isCompleted && progress.watchTimeSeconds > 0
    ).toList();

    // Sort by most recent
    inProgressList.sort((a, b) =>
        b.startTime.compareTo(a.startTime)
    );

    // Get content for the most recent in-progress lesson
    if (inProgressList.isNotEmpty) {
      final contentId = inProgressList.first.contentId;
      return await databaseService.getContent(contentId);
    }

    return null;
  }

  void _goToEducationPlan() {
    AppRouter.navigateTo('/education-plan');

    // Log event
    final analyticsService = Provider.of<AnalyticsService>(context, listen: false);
    analyticsService.logFeatureUse('view_education_plan');
  }

  void _goToProgressReport() {
    AppRouter.navigateTo('/progress-report');

    // Log event
    final analyticsService = Provider.of<AnalyticsService>(context, listen: false);
    analyticsService.logViewProgress();
  }

  void _goToTodaysLesson() async {
    final upcomingLessons = await _upcomingLessonsFuture;

    if (upcomingLessons.isNotEmpty) {
      final lesson = upcomingLessons.first;

      // Navigate based on content type
      if (lesson.contentType == ContentType.video ||
          (lesson.contentType == ContentType.mixed && lesson.hasVideo)) {
        AppRouter.navigateTo('/lesson-player', arguments: lesson);
      } else {
        AppRouter.navigateTo('/slide-viewer', arguments: lesson);
      }

      // Log event
      final analyticsService = Provider.of<AnalyticsService>(context, listen: false);
      analyticsService.logLessonStart(lesson.id, lesson.title);
    } else {
      // Show a message if there are no upcoming lessons
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have completed all available lessons!'),
        ),
      );
    }
  }

  void _goToContinueLesson(ContentModel lesson) {
    // Navigate based on content type
    if (lesson.contentType == ContentType.video ||
        (lesson.contentType == ContentType.mixed && lesson.hasVideo)) {
      AppRouter.navigateTo('/lesson-player', arguments: lesson);
    } else {
      AppRouter.navigateTo('/slide-viewer', arguments: lesson);
    }

    // Log event
    final analyticsService = Provider.of<AnalyticsService>(context, listen: false);
    analyticsService.logLessonStart(lesson.id, lesson.title);
  }

  void _goToUpcomingLesson(ContentModel lesson) {
    // Navigate based on content type
    if (lesson.contentType == ContentType.video ||
        (lesson.contentType == ContentType.mixed && lesson.hasVideo)) {
      AppRouter.navigateTo('/lesson-player', arguments: lesson);
    } else {
      AppRouter.navigateTo('/slide-viewer', arguments: lesson);
    }

    // Log event
    final analyticsService = Provider.of<AnalyticsService>(context, listen: false);
    analyticsService.logLessonStart(lesson.id, lesson.title);
  }

  void _goToAchievements() {
    AppRouter.navigateTo('/achievements');

    // Log event
    final analyticsService = Provider.of<AnalyticsService>(context, listen: false);
    analyticsService.logFeatureUse('view_achievements');
  }

  void _signOut() async {
    // Log event
    final analyticsService = Provider.of<AnalyticsService>(context, listen: false);
    analyticsService.logSessionEnd();

    // Sign out
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.signOut();

    // Navigate to login
    AppRouter.navigateToAndRemoveUntil('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(StringConstants.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => AppRouter.navigateTo('/settings'),
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _loadUserData();
          });
        },
        child: FutureBuilder<UserModel?>(
          future: _userFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingIndicator();
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            }

            final user = snapshot.data;
            if (user == null) {
              return const Center(
                child: Text('No user data found'),
              );
            }

            return _buildHomeContent(user);
          },
        ),
      ),
    );
  }

  Widget _buildHomeContent(UserModel user) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Welcome message
        Text(
          'Welcome back, ${user.fullName.split(' ').first}!',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Continue your diabetes education journey',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 24),

        // Gamification cards
        Row(
          children: [
            // Daily streak
            Expanded(
              child: DailyStreakCard(
                streakCount: user.streakDays,
                onTap: _goToEducationPlan,
              ),
            ),
            const SizedBox(width: 16),

            // Points
            Expanded(
              child: PointsCard(
                pointsCount: user.points,
                onTap: _goToAchievements,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Today's lesson button
        ElevatedButton.icon(
          onPressed: _goToTodaysLesson,
          icon: const Icon(Icons.play_circle_outline),
          label: const Text(StringConstants.todaysLesson),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // View progress button
        OutlinedButton.icon(
          onPressed: _goToProgressReport,
          icon: const Icon(Icons.bar_chart_outlined),
          label: const Text(StringConstants.viewProgress),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Continue where you left off
        FutureBuilder<ContentModel?>(
          future: _currentLessonFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 100,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final currentLesson = snapshot.data;
            if (currentLesson == null) {
              return const SizedBox.shrink();
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  StringConstants.continueWhereYouLeftOff,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ContinueLessonCard(
                  lesson: currentLesson,
                  onTap: () => _goToContinueLesson(currentLesson),
                ),
                const SizedBox(height: 24),
              ],
            );
          },
        ),

        // Upcoming lessons
        Text(
          StringConstants.upcomingLessons,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        FutureBuilder<List<ContentModel>>(
          future: _upcomingLessonsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 200,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            }

            final upcomingLessons = snapshot.data ?? [];

            if (upcomingLessons.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                  ),
                ),
                child: const Text(
                  'You have completed all available lessons! Check back later for new content.',
                  textAlign: TextAlign.center,
                ),
              );
            }

            return ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: upcomingLessons.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final lesson = upcomingLessons[index];
                return UpcomingLessonCard(
                  lesson: lesson,
                  onTap: () => _goToUpcomingLesson(lesson),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: FutureBuilder<UserModel?>(
        future: _userFuture,
        builder: (context, snapshot) {
          final user = snapshot.data;

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              UserAccountsDrawerHeader(
                accountName: Text(user?.fullName ?? 'User'),
                accountEmail: Text(user?.email ?? ''),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  child: const Icon(Icons.person),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.home_outlined),
                title: const Text('Home'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.menu_book_outlined),
                title: const Text('Education Plan'),
                onTap: () {
                  Navigator.pop(context);
                  _goToEducationPlan();
                },
              ),
              ListTile(
                leading: const Icon(Icons.bar_chart_outlined),
                title: const Text('Progress Report'),
                onTap: () {
                  Navigator.pop(context);
                  _goToProgressReport();
                },
              ),
              ListTile(
                leading: const Icon(Icons.emoji_events_outlined),
                title: const Text('Achievements'),
                onTap: () {
                  Navigator.pop(context);
                  _goToAchievements();
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Settings'),
                onTap: () {
                  Navigator.pop(context);
                  AppRouter.navigateTo('/settings');
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Sign Out'),
                onTap: _signOut,
              ),
            ],
          );
        },
      ),
    );
  }
}
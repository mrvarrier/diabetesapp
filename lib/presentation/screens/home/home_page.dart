// File: lib/presentation/screens/home/home_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/constants.dart';
import '../../../core/utils/app_colors.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/providers/content_provider.dart';
import '../../../domain/providers/progress_provider.dart';
import '../../../domain/providers/achievements_provider.dart';
import '../../../data/models/content_model.dart';
import '../../../data/models/achievement_model.dart';
import '../../widgets/content_card_widget.dart';
import '../../widgets/achievement_badge_widget.dart';
import '../../widgets/progress_chart_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    // Get providers
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final contentProvider = Provider.of<ContentProvider>(context, listen: false);

    if (authProvider.user != null) {
      // Load content for user
      await contentProvider.loadContentForUser(
        authProvider.user!.id,
        authProvider.user!.diabetesType,
        authProvider.user!.treatmentMethod,
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  void _navigateToContentDetails(Content content) {
    final contentProvider = Provider.of<ContentProvider>(context, listen: false);
    contentProvider.setSelectedContent(content);

    if (content.contentType == AppConstants.contentTypeVideo) {
      Navigator.of(context).pushNamed(
        AppConstants.lessonPlayerRoute,
        arguments: content,
      );
    } else if (content.contentType == AppConstants.contentTypeSlide) {
      Navigator.of(context).pushNamed(
        AppConstants.slideViewerRoute,
        arguments: content,
      );
    }
  }

  void _navigateToEducationPlan() {
    Navigator.of(context).pushNamed(AppConstants.educationPlanRoute);
  }

  void _navigateToAchievements() {
    Navigator.of(context).pushNamed(AppConstants.achievementsRoute);
  }

  void _navigateToProgress() {
    Navigator.of(context).pushNamed(AppConstants.progressReportRoute);
  }

  void _navigateToSettings() {
    Navigator.of(context).pushNamed(AppConstants.settingsRoute);
  }

  Content? _getNextLesson(List<Content> contents, List<String> completedContentIds) {
    // Find the first incomplete content
    for (final content in contents) {
      if (!completedContentIds.contains(content.id)) {
        return content;
      }
    }

    // If all content is completed, return the first one for review
    return contents.isNotEmpty ? contents.first : null;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final contentProvider = Provider.of<ContentProvider>(context);
    final progressProvider = Provider.of<ProgressProvider>(context);
    final achievementsProvider = Provider.of<AchievementsProvider>(context);

    final user = authProvider.user;
    final contents = contentProvider.contents;
    final progressList = progressProvider.progressList;
    final achievements = achievementsProvider.achievements;

    // Get completed content IDs
    final completedContentIds = progressList
        .where((progress) => progress.isCompleted)
        .map((progress) => progress.contentId)
        .toList();

    // Calculate completion stats
    final stats = progressProvider.calculateCompletionStats(contents);

    // Get next lesson
    final nextLesson = _getNextLesson(contents, completedContentIds);

    return Scaffold(
      appBar: AppBar(
        title: Text(user?.name.split(' ').first ?? 'Welcome'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _navigateToSettings,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User info and stats card
              _buildUserInfoCard(user, stats),
              const SizedBox(height: 24),

              // Next lesson section
              const Text(
                'Continue Learning',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              nextLesson != null
                  ? _buildNextLessonCard(nextLesson)
                  : _buildAllCompletedCard(),
              const SizedBox(height: 24),

              // Recent achievements
              _buildRecentAchievements(achievements),
              const SizedBox(height: 24),

              // Learning path button
              _buildLearningPathButton(),
              const SizedBox(height: 24),

              // Recent content
              const Text(
                'Recent Content',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _buildRecentContent(contents),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoCard(user, Map<String, dynamic> stats) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // User avatar or icon
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    user?.name.substring(0, 1) ?? 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // User info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'User',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Points: ${stats['totalPointsEarned']}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Current streak badge
                if (user?.currentStreak != null && user!.currentStreak > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.local_fire_department,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${user.currentStreak} day${user.currentStreak > 1 ? 's' : ''}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Progress chart
            const Text(
              'Learning Progress',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            ProgressChartWidget(
              completedCount: stats['completedCount'],
              totalCount: stats['totalCount'],
              completionPercentage: stats['completionPercentage'],
            ),
            const SizedBox(height: 8),
            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Completed',
                  '${stats['completedCount']}/${stats['totalCount']}',
                  Icons.check_circle,
                  AppColors.success,
                ),
                _buildStatItem(
                  'Points',
                  '${stats['totalPointsEarned']}',
                  Icons.stars,
                  AppColors.accentColor,
                ),
                _buildStatItem(
                  'Streak',
                  '${user?.currentStreak ?? 0} days',
                  Icons.local_fire_department,
                  AppColors.error,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildNextLessonCard(Content lesson) {
    return GestureDetector(
      onTap: () => _navigateToContentDetails(lesson),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Lesson icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      lesson.contentType == AppConstants.contentTypeVideo
                          ? Icons.play_circle_fill
                          : Icons.slideshow,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Lesson info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            lesson.contentType == AppConstants.contentTypeVideo
                                ? 'Video Lesson'
                                : 'Slide Presentation',
                            style: const TextStyle(
                              color: AppColors.primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          lesson.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lesson.description,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Start button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _navigateToContentDetails(lesson),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Start Lesson',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        lesson.contentType == AppConstants.contentTypeVideo
                            ? Icons.play_arrow
                            : Icons.slideshow,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAllCompletedCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(
              Icons.check_circle,
              color: AppColors.success,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'All Lessons Completed!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Congratulations! You have completed all available lessons. Check back later for new content.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _navigateToEducationPlan,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Review Education Plan'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentAchievements(List<Achievement> achievements) {
    // Show only the 3 most recent achievements
    final recentAchievements = achievements.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Achievements',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: _navigateToAchievements,
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        recentAchievements.isEmpty
            ? _buildNoAchievementsCard()
            : SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: recentAchievements.length,
            itemBuilder: (context, index) {
              final achievement = recentAchievements[index];
              return AchievementBadgeWidget(
                achievement: achievement,
                size: 80,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNoAchievementsCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: const [
            Icon(
              Icons.emoji_events_outlined,
              color: AppColors.textSecondary,
              size: 32,
            ),
            SizedBox(height: 8),
            Text(
              'Complete lessons to earn achievements',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLearningPathButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _navigateToEducationPlan,
        icon: const Icon(Icons.map_outlined),
        label: const Text('View Learning Path'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentContent(List<Content> contents) {
    // Show at most 5 content items
    final displayContents = contents.take(5).toList();

    return displayContents.isEmpty
        ? _buildNoContentCard()
        : ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayContents.length,
      itemBuilder: (context, index) {
        final content = displayContents[index];
        return ContentCardWidget(
          content: content,
          onTap: () => _navigateToContentDetails(content),
        );
      },
    );
  }

  Widget _buildNoContentCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: const [
            Icon(
              Icons.content_paste_off,
              color: AppColors.textSecondary,
              size: 32,
            ),
            SizedBox(height: 8),
            Text(
              'No content available yet',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
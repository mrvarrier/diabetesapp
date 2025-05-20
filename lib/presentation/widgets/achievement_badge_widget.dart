// File: lib/presentation/widgets/achievement_badge_widget.dart

import 'package:flutter/material.dart';
import '../../config/constants.dart';
import '../../core/utils/app_colors.dart';
import '../../data/models/achievement_model.dart';

class AchievementBadgeWidget extends StatelessWidget {
  final Achievement achievement;
  final double size;
  final bool showDetails;

  const AchievementBadgeWidget({
    Key? key,
    required this.achievement,
    this.size = 80,
    this.showDetails = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showAchievementDetails(context),
      child: Container(
        width: size,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            // Badge icon
            Container(
              width: size * 0.8,
              height: size * 0.8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getAchievementColor().withOpacity(0.1),
                border: Border.all(
                  color: _getAchievementColor(),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _getAchievementColor().withOpacity(0.3),
                    blurRadius: 6,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                _getAchievementIcon(),
                color: _getAchievementColor(),
                size: size * 0.4,
              ),
            ),
            if (showDetails) ...[
              const SizedBox(height: 8),
              // Achievement title
              Text(
                achievement.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Points awarded
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '+${achievement.pointsAwarded}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 4),
              // Shorter title
              Text(
                _getShortTitle(),
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAchievementDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getAchievementColor().withOpacity(0.1),
              ),
              child: Icon(
                _getAchievementIcon(),
                color: _getAchievementColor(),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                achievement.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              achievement.description,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  Icons.star,
                  color: AppColors.accentColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${achievement.pointsAwarded} points earned',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accentColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: AppColors.textTertiary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Earned on ${_formatDate(achievement.awardedAt)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  IconData _getAchievementIcon() {
    switch (achievement.achievementType) {
      case AppConstants.achievementFirstLesson:
        return Icons.school;
      case AppConstants.achievement100Points:
      case AppConstants.achievement500Points:
      case AppConstants.achievement1000Points:
        return Icons.stars;
      case AppConstants.achievementPerfectQuiz:
        return Icons.emoji_events;
      case AppConstants.achievement3DayStreak:
      case AppConstants.achievement7DayStreak:
        return Icons.local_fire_department;
      case AppConstants.achievementCompletePlan:
        return Icons.workspace_premium;
      default:
        return Icons.emoji_events;
    }
  }

  Color _getAchievementColor() {
    switch (achievement.achievementType) {
      case AppConstants.achievementFirstLesson:
        return Colors.blue;
      case AppConstants.achievement100Points:
        return Colors.amber;
      case AppConstants.achievement500Points:
      case AppConstants.achievement1000Points:
        return Colors.orange;
      case AppConstants.achievementPerfectQuiz:
        return AppColors.success;
      case AppConstants.achievement3DayStreak:
      case AppConstants.achievement7DayStreak:
        return Colors.red;
      case AppConstants.achievementCompletePlan:
        return Colors.purple;
      default:
        return AppColors.primaryColor;
    }
  }

  String _getShortTitle() {
    // Shorter titles for compact display
    switch (achievement.achievementType) {
      case AppConstants.achievementFirstLesson:
        return 'First Lesson';
      case AppConstants.achievement100Points:
        return '100 Points';
      case AppConstants.achievement500Points:
        return '500 Points';
      case AppConstants.achievement1000Points:
        return '1000 Points';
      case AppConstants.achievementPerfectQuiz:
        return 'Perfect Quiz';
      case AppConstants.achievement3DayStreak:
        return '3-Day Streak';
      case AppConstants.achievement7DayStreak:
        return '7-Day Streak';
      case AppConstants.achievementCompletePlan:
        return 'Plan Master';
      default:
        return achievement.title;
    }
  }

  String _formatDate(DateTime date) {
    // Format: Jan 1, 2023
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
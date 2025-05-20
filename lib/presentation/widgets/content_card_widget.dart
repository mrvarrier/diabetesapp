// File: lib/presentation/widgets/content_card_widget.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../core/utils/app_colors.dart';
import '../../data/models/content_model.dart';
import '../../domain/providers/progress_provider.dart';

class ContentCardWidget extends StatelessWidget {
  final Content content;
  final VoidCallback onTap;

  const ContentCardWidget({
    Key? key,
    required this.content,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final progressProvider = Provider.of<ProgressProvider>(context);
    final progress = progressProvider.progressList.firstWhere(
          (p) => p.contentId == content.id,
      orElse: () => null as dynamic,
    );

    final isCompleted = progress?.isCompleted ?? false;
    final progressPercentage = progress?.progressPercentage ?? 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            // Content info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Content icon/thumbnail
                  _buildContentThumbnail(),
                  const SizedBox(width: 12),
                  // Content details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Content type badge
                        _buildContentTypeBadge(),
                        const SizedBox(height: 4),
                        // Content title
                        Text(
                          content.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Points and duration
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              color: AppColors.accentColor,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${content.pointsToEarn} points',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            if (content.duration != null) ...[
                              Icon(
                                Icons.access_time,
                                color: AppColors.textTertiary,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDuration(content.duration!),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Completion status
                  _buildCompletionStatus(isCompleted),
                ],
              ),
            ),
            // Progress bar
            if (progressPercentage > 0 && !isCompleted)
              LinearProgressIndicator(
                value: progressPercentage / 100,
                backgroundColor: AppColors.progressBarBackground,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                minHeight: 4,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentThumbnail() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(8),
        image: content.thumbnailUrl != null
            ? DecorationImage(
          image: NetworkImage(content.thumbnailUrl!),
          fit: BoxFit.cover,
        )
            : null,
      ),
      child: content.thumbnailUrl == null
          ? Icon(
        content.contentType == AppConstants.contentTypeVideo
            ? Icons.play_circle_fill
            : Icons.slideshow,
        color: Colors.white,
        size: 32,
      )
          : null,
    );
  }

  Widget _buildContentTypeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: _getContentTypeColor(),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _getContentTypeLabel(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCompletionStatus(bool isCompleted) {
    return isCompleted
        ? Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.check_circle,
        color: AppColors.success,
        size: 20,
      ),
    )
        : const Icon(
      Icons.chevron_right,
      color: AppColors.textSecondary,
      size: 24,
    );
  }

  Color _getContentTypeColor() {
    switch (content.contentType) {
      case AppConstants.contentTypeVideo:
        return Colors.red;
      case AppConstants.contentTypeSlide:
        return Colors.blue;
      case AppConstants.contentTypeQuiz:
        return Colors.orange;
      default:
        return AppColors.primaryColor;
    }
  }

  String _getContentTypeLabel() {
    switch (content.contentType) {
      case AppConstants.contentTypeVideo:
        return 'VIDEO';
      case AppConstants.contentTypeSlide:
        return 'SLIDES';
      case AppConstants.contentTypeQuiz:
        return 'QUIZ';
      default:
        return 'LESSON';
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;

    if (minutes == 0) {
      return '$seconds sec';
    } else if (seconds == 0) {
      return '$minutes min';
    } else {
      return '$minutes:${seconds.toString().padLeft(2, '0')} min';
    }
  }
}
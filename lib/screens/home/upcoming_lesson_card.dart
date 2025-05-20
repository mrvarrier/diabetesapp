import 'package:flutter/material.dart';
import '../../models/content_model.dart';

class UpcomingLessonCard extends StatelessWidget {
  final ContentModel lesson;
  final VoidCallback onTap;

  const UpcomingLessonCard({
    Key? key,
    required this.lesson,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Content type icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getContentColor(context, lesson.contentType).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getContentIcon(lesson.contentType, lesson.hasVideo),
                  color: _getContentColor(context, lesson.contentType),
                ),
              ),
              const SizedBox(width: 16),

              // Lesson info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${lesson.estimatedDuration} min',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _buildContentTypeChip(context, lesson.contentType, lesson.hasVideo),
                      ],
                    ),
                  ],
                ),
              ),

              // Start button
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentTypeChip(BuildContext context, ContentType contentType, bool hasVideo) {
    String label;
    Color color;

    switch (contentType) {
      case ContentType.video:
        label = 'Video';
        color = Colors.blue;
        break;
      case ContentType.slides:
        label = 'Slides';
        color = Colors.orange;
        break;
      case ContentType.mixed:
        label = hasVideo ? 'Video & Slides' : 'Slides';
        color = hasVideo ? Colors.purple : Colors.orange;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  IconData _getContentIcon(ContentType contentType, bool hasVideo) {
    switch (contentType) {
      case ContentType.video:
        return Icons.play_circle_outline;
      case ContentType.slides:
        return Icons.slideshow;
      case ContentType.mixed:
        return hasVideo ? Icons.play_circle_outline : Icons.slideshow;
    }
  }

  Color _getContentColor(BuildContext context, ContentType contentType) {
    switch (contentType) {
      case ContentType.video:
        return Colors.blue;
      case ContentType.slides:
        return Colors.orange;
      case ContentType.mixed:
        return Colors.purple;
    }
  }
}
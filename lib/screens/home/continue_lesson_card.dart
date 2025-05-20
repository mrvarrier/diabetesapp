import 'package:flutter/material.dart';
import '../../models/content_model.dart';

class ContinueLessonCard extends StatelessWidget {
  final ContentModel lesson;
  final VoidCallback onTap;

  const ContinueLessonCard({
    Key? key,
    required this.lesson,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Continue label
              Row(
                children: [
                  Icon(
                    Icons.play_arrow,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Continue Learning',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Lesson info
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thumbnail or icon
                  Container(
                    width: 80,
                    height: 60,
                    decoration: BoxDecoration(
                      color: _getContentColor(context, lesson.contentType).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: lesson.hasVideo
                        ? Stack(
                      alignment: Alignment.center,
                      children: [
                        // When we have actual thumbnails, we would show an image here
                        Icon(
                          Icons.play_circle_outline,
                          size: 32,
                          color: _getContentColor(context, lesson.contentType),
                        ),
                      ],
                    )
                        : Icon(
                      Icons.slideshow,
                      size: 32,
                      color: _getContentColor(context, lesson.contentType),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Title and progress
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
                        const SizedBox(height: 8),

                        // Progress bar (would be actual progress in a real app)
                        // For MVP, we'll just show a fixed progress
                        LinearProgressIndicator(
                          value: 0.4, // Mock progress value
                          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '40% completed', // Mock progress text
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Continue button
              OutlinedButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Continue'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
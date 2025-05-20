// File: lib/presentation/screens/education/lesson_player.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../../config/constants.dart';
import '../../../core/utils/app_colors.dart';
import '../../../data/models/content_model.dart';
import '../../../data/models/progress_model.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/providers/content_provider.dart';
import '../../../domain/providers/progress_provider.dart';
import '../../../domain/providers/achievements_provider.dart';

class LessonPlayer extends StatefulWidget {
  final Content content;

  const LessonPlayer({
    Key? key,
    required this.content,
  }) : super(key: key);

  @override
  State<LessonPlayer> createState() => _LessonPlayerState();
}

class _LessonPlayerState extends State<LessonPlayer> {
  late YoutubePlayerController _controller;
  bool _isLoading = true;
  bool _isPlayerReady = false;
  bool _isCompleted = false;
  int _lastPosition = 0;
  int _totalDuration = 0;
  Progress? _progress;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    // Get video ID
    final videoId = widget.content.youtubeVideoId;
    if (videoId == null) {
      // Handle missing video ID
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // Initialize controller with YouTube iFrame API
    _controller = YoutubePlayerController(
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        autoPlay: true,
        enableCaption: true,
        mute: false,
      ),
    );

    // Load the video
    await _controller.loadVideoById(videoId: videoId);

    // Set up listeners
    _controller.listen((state) {
      if (!_isPlayerReady && state.isReady) {
        setState(() {
          _isPlayerReady = true;
          if (state.metaData.duration.inSeconds > 0) {
            _totalDuration = state.metaData.duration.inSeconds;
          }

          // Seek to last position if not completed
          if (!_isCompleted && _lastPosition > 0) {
            _controller.seekTo(seconds: _lastPosition.toDouble());
          }
        });
      }

      // Update position
      if (_isPlayerReady) {
        setState(() {
          _lastPosition = state.position.inSeconds;
        });

        // Check video end
        if (state.playerState == PlayerState.ended) {
          _completeLesson();
        }

        // Update progress every 10 seconds
        if (_lastPosition > 0 && _lastPosition % 10 == 0) {
          _updateProgress(false);
        }
      }
    });

    // Load progress
    await _loadProgress();

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadProgress() async {
    // Get progress provider
    final progressProvider = Provider.of<ProgressProvider>(context, listen: false);

    // Get or create progress
    try {
      final progress = await progressProvider.getContentProgress(widget.content.id);

      if (progress != null) {
        // Existing progress
        setState(() {
          _progress = progress;
          _isCompleted = progress.isCompleted;

          // Restore video position if available
          if (progress.videoProgress != null) {
            final lastPosition = progress.videoProgress!['lastPosition'] as int?;
            if (lastPosition != null && lastPosition > 0) {
              _lastPosition = lastPosition;

              // Seek to last position if not completed
              if (!_isCompleted && _isPlayerReady) {
                _controller.seekTo(seconds: _lastPosition.toDouble());
              }
            }
          }
        });
      } else {
        // Start new progress
        final newProgress = await progressProvider.startContentProgress(widget.content);
        setState(() {
          _progress = newProgress;
          _isCompleted = newProgress.isCompleted;
        });
      }
    } catch (e) {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load progress: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _updateProgress(bool isComplete) async {
    if (_progress == null) return;

    // Get providers
    final progressProvider = Provider.of<ProgressProvider>(context, listen: false);

    try {
      // Update progress
      final updatedProgress = await progressProvider.updateVideoProgress(
        contentId: widget.content.id,
        currentPosition: _lastPosition,
        totalDuration: _totalDuration > 0 ? _totalDuration : 100,
        isCompleted: isComplete,
        pointsToAward: widget.content.pointsToEarn,
      );

      setState(() {
        _progress = updatedProgress;
        _isCompleted = updatedProgress.isCompleted;
      });

      // Check for points earned
      if (isComplete && !_isCompleted) {
        // Award points
        await _awardPoints(widget.content.pointsToEarn);

        // Check if first lesson completed
        final isFirstLesson = progressProvider.progressList
            .where((p) => p.isCompleted)
            .length == 1;

        // Check achievements
        await _checkAchievements(isFirstLesson: isFirstLesson);

        // Update streak
        await _updateStreak();
      }
    } catch (e) {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update progress: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _completeLesson() async {
    if (_isCompleted) return;

    // Update progress as completed
    await _updateProgress(true);

    // Show completion dialog
    if (mounted) {
      _showCompletionDialog();
    }
  }

  Future<void> _awardPoints(int points) async {
    // Get auth provider to update user points
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Refresh user data (will update points)
    await authProvider.refreshUserData();
  }

  Future<void> _checkAchievements({bool isFirstLesson = false}) async {
    // Get providers
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final achievementsProvider = Provider.of<AchievementsProvider>(context, listen: false);

    // Check for achievements
    await achievementsProvider.checkAndAwardAchievements(
      isFirstLesson: isFirstLesson,
      currentPoints: authProvider.user?.totalPoints,
      streakDays: authProvider.user?.currentStreak,
    );
  }

  Future<void> _updateStreak() async {
    // Get auth provider
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Update streak
    await authProvider.updateStreakAfterCompletion();
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(
              Icons.check_circle,
              color: AppColors.success,
              size: 24,
            ),
            SizedBox(width: 12),
            Text('Lesson Completed!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Congratulations! You have successfully completed this lesson.',
              style: TextStyle(
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
                  '+${widget.content.pointsToEarn} points earned',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accentColor,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (widget.content.quizId != null)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToQuiz();
              },
              child: const Text('Take Quiz'),
            ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToLessonCompletion();
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _navigateToQuiz() {
    Navigator.of(context).pushReplacementNamed(
      AppConstants.quizRoute,
      arguments: {
        'quizId': widget.content.quizId,
        'lessonId': widget.content.id,
      },
    );
  }

  void _navigateToLessonCompletion() {
    Navigator.of(context).pushReplacementNamed(
      AppConstants.lessonCompletionRoute,
      arguments: {
        'lessonId': widget.content.id,
        'pointsEarned': widget.content.pointsToEarn,
      },
    );
  }

  @override
  void dispose() {
    // Update progress before disposing
    if (_isPlayerReady && !_isCompleted && _lastPosition > 0) {
      _updateProgress(false);
    }

    // Dispose controller
    _controller.close();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.content.title),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // YouTube player
              _buildYouTubePlayer(),

              // Content details
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                // Title and progress
                Row(
                children: [
                // Content type badge
                Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'VIDEO LESSON',
                  style: TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              // Completion status
              if (_isCompleted)
                Row(
                  children: const [
                    Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Completed',
                      style: TextStyle(
                        color: AppColors.success,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
              else if (_progress != null)
                Text(
                  '${(_progress!.progressPercentage).toStringAsFixed(0)}% Complete',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Title
          Text(
            widget.content.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),

          // Points and duration
          Row(
            children: [
              const Icon(
                Icons.star,
                color: AppColors.accentColor,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '${widget.content.pointsToEarn} points',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 16),
              if (widget.content.duration != null) ...[
                const Icon(
                  Icons.access_time,
                  color: AppColors.textTertiary,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDuration(widget.content.duration!),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Description
          const Text(
            'Description',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.content.description,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Tags
          if (widget.content.tags.isNotEmpty) ...[
      const Text(
      'Topics',
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    ),
    const SizedBox(height: 8),
    Wrap(
    spacing: 8,
    runSpacing: 8,
    children: widget.content.tags.map((tag) => Chip(
    label: Text(tag),
    backgroundColor: AppColors.primaryLight.withOpacity(0.1),
    labelStyle: const TextStyle(
    color: AppColors.primaryColor,
    fontSize: 12,
    ),
    )).toList(),
    ),
    const SizedBox(height: 24),
    ],

    // Quiz link if available
    if (widget.content.quizId != null && _isCompleted)
    ElevatedButton.icon(
    onPressed: _navigateToQuiz,
    icon: const Icon(Icons.quiz),
    label: const Text('Take the Quiz'),
    style: ElevatedButton.styleFrom(
    padding: const EdgeInsets.symmetric(vertical: 12),
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(10),
    ),
    ),
    ),
                    // Manual complete button (for testing or if video doesn't work)
                    if (!_isCompleted)
                      OutlinedButton.icon(
                        onPressed: () => _completeLesson(),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Mark as Completed'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
      ),
    );
  }

  Widget _buildYouTubePlayer() {
    if (widget.content.youtubeVideoId == null) {
      return Container(
        height: 200,
        color: Colors.black,
        child: const Center(
          child: Text(
            'Video not available',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    // Using YoutubePlayerIFrame instead of YoutubePlayer
    return YoutubePlayer(
      controller: _controller,
      aspectRatio: 16 / 9,
    );
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
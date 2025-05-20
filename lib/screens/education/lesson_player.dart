import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../models/content_model.dart';
import '../../services/youtube_service.dart';
import '../../services/database_service.dart';
import '../../services/points_service.dart';
import '../../services/analytics_service.dart';
import '../../services/connectivity_plus/connectivity_plus.dart';
import '../../navigation/app_router.dart';
import '../widgets/loading_indicator.dart';
import 'quiz_button.dart';

class LessonPlayer extends StatefulWidget {
  final ContentModel content;

  const LessonPlayer({
    Key? key,
    required this.content,
  }) : super(key: key);

  @override
  _LessonPlayerState createState() => _LessonPlayerState();
}

class _LessonPlayerState extends State<LessonPlayer> {
  late YoutubePlayerController _controller;
  bool _isLoading = true;
  bool _isInitialized = false;
  bool _hasInternetConnection = true;
  bool _isVideoCompleted = false;
  bool _isContentCompleted = false;
  bool _hasQuiz = false;
  String? _errorMessage;

  int _watchTimeSeconds = 0;
  String _progressId = '';

  // Position tracking timer
  Timer? _positionTimer;

  @override
  void initState() {
    super.initState();
    _initPlayer();
    _checkQuizAvailability();
    _checkConnectionStatus();

    // Log analytics
    final analyticsService = Provider.of<AnalyticsService>(context, listen: false);
    analyticsService.logLessonStart(widget.content.id, widget.content.title);
  }

  @override
  void dispose() {
    _positionTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initPlayer() async {
    try {
      final youtubeService = Provider.of<YouTubeService>(context, listen: false);

      // Initialize progress tracking
      await _initProgressTracking();

      // Get saved playback position if any
      final savedPosition = await youtubeService.getPlaybackPosition(widget.content.youtubeVideoId);

      // Create controller
      _controller = YoutubePlayerController(
        initialVideoId: widget.content.youtubeVideoId,
        flags: YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
          disableDragSeek: false,
          loop: false,
          enableCaption: true,
          startAt: savedPosition,
        ),
      );

      // Add listeners
      _controller.addListener(_onPlayerStateChange);

      // Start position tracking timer
      _startPositionTracking();

      setState(() {
        _isLoading = false;
        _isInitialized = true;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load video: ${e.toString()}';
      });
    }
  }

  Future<void> _initProgressTracking() async {
    final databaseService = Provider.of<DatabaseService>(context, listen: false);
    final userId = Provider.of<AuthService>(context, listen: false).uid;

    if (userId != null) {
      // Start content progress
      _progressId = await databaseService.startContentProgress(userId, widget.content.id);

      // Check if content is already completed
      final progress = await databaseService.getUserContentProgress(userId, widget.content.id);
      if (progress != null) {
        _isContentCompleted = progress.isCompleted;
        _watchTimeSeconds = progress.watchTimeSeconds;
      }
    }
  }

  void _startPositionTracking() {
    _positionTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_controller.value.isPlaying) {
        _updatePlaybackPosition();
      }
    });
  }

  Future<void> _updatePlaybackPosition() async {
    if (!_isInitialized) return;

    final youtubeService = Provider.of<YouTubeService>(context, listen: false);
    final databaseService = Provider.of<DatabaseService>(context, listen: false);

    // Get current position
    final position = _controller.value.position.inSeconds;

    // Save position
    await youtubeService.savePlaybackPosition(widget.content.youtubeVideoId, position);

    // Update watch time in database
    if (_progressId.isNotEmpty) {
      await databaseService.updateWatchTime(_progressId, position);

      // Update local watch time
      setState(() {
        _watchTimeSeconds = position;
      });

      // Check if video is completed
      final videoDuration = _controller.metadata.duration.inSeconds;
      if (position >= (videoDuration * 0.8) && !_isVideoCompleted) {
        _markVideoAsCompleted(videoDuration);
      }
    }
  }

  Future<void> _markVideoAsCompleted(int duration) async {
    setState(() {
      _isVideoCompleted = true;
    });

    // Log analytics
    final analyticsService = Provider.of<AnalyticsService>(context, listen: false);
    analyticsService.logVideoComplete(
      widget.content.youtubeVideoId,
      widget.content.id,
      duration,
      _watchTimeSeconds,
    );

    // Award points if content not already completed
    if (!_isContentCompleted) {
      final pointsService = Provider.of<PointsService>(context, listen: false);
      await pointsService.awardVideoPoints(widget.content.id);

      setState(() {
        _isContentCompleted = true;
      });
    }
  }

  void _onPlayerStateChange() {
    if (_controller.value.playerState == PlayerState.ended && !_isVideoCompleted) {
      final videoDuration = _controller.metadata.duration.inSeconds;
      _markVideoAsCompleted(videoDuration);
    }
  }

  Future<void> _checkQuizAvailability() async {
    final databaseService = Provider.of<DatabaseService>(context, listen: false);
    final quiz = await databaseService.getContentQuiz(widget.content.id);

    setState(() {
      _hasQuiz = quiz != null;
    });
  }

  Future<void> _checkConnectionStatus() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _hasInternetConnection = connectivityResult != ConnectivityResult.none;
    });
  }

  void _navigateToQuiz() {
    // Save current position before navigating
    _updatePlaybackPosition();

    AppRouter.navigateTo('/quiz', arguments: {
      'contentId': widget.content.id,
    });
  }

  void _navigateToSlides() {
    // Save current position before navigating
    _updatePlaybackPosition();

    AppRouter.navigateTo('/slide-viewer', arguments: widget.content);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.content.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showLessonInfo(context),
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Loading video...')
          : _errorMessage != null
          ? _buildErrorView()
          : _buildVideoPlayer(),
    );
  }

  Widget _buildVideoPlayer() {
    return Column(
      children: [
        // YouTube player
        !_hasInternetConnection
            ? _buildOfflineView()
            : YoutubePlayer(
          controller: _controller,
          showVideoProgressIndicator: true,
          progressIndicatorColor: Theme.of(context).colorScheme.primary,
          progressColors: ProgressBarColors(
            playedColor: Theme.of(context).colorScheme.primary,
            handleColor: Theme.of(context).colorScheme.primary,
          ),
          onReady: () {
            setState(() {
              _isInitialized = true;
            });
          },
        ),

        // Video completed indicator
        if (_isVideoCompleted)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: Colors.green.shade100,
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green.shade700,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Video completed',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

        // Content description and additional options
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  widget.content.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Duration info
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.content.estimatedDuration} minutes',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Description
                Text(
                  widget.content.description,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),

                // Quiz button (if available)
                if (_hasQuiz)
                  QuizButton(
                    isCompleted: _isContentCompleted,
                    onTap: _navigateToQuiz,
                  ),

                // Slides button (if available)
                if (widget.content.hasSlides)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: OutlinedButton.icon(
                      onPressed: _navigateToSlides,
                      icon: const Icon(Icons.slideshow),
                      label: const Text('View Slides'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        minimumSize: const Size(double.infinity, 0),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Video',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'An unknown error occurred.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _initPlayer();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineView() {
    return Container(
      width: double.infinity,
      height: 250,
      color: Colors.black,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.wifi_off,
            color: Colors.white,
            size: 48,
          ),
          const SizedBox(height: 16),
          const Text(
            'You\'re offline',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please connect to the internet to watch this video',
            style: TextStyle(
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () async {
              await _checkConnectionStatus();
              if (_hasInternetConnection) {
                _initPlayer();
              }
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  void _showLessonInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'About This Lesson',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildInfoRow(
                context,
                Icons.title,
                'Title',
                widget.content.title,
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                context,
                Icons.description,
                'Description',
                widget.content.description,
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                context,
                Icons.access_time,
                'Duration',
                '${widget.content.estimatedDuration} minutes',
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                context,
                Icons.stars,
                'Points',
                '${widget.content.pointsValue} points upon completion',
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                context,
                Icons.quiz,
                'Quiz',
                _hasQuiz ? 'Available' : 'Not available',
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
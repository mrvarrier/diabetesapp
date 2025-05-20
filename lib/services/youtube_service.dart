import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'database_service.dart';
import 'content_service.dart';

class YouTubeService {
  final DatabaseService _databaseService;
  final ContentService _contentService;

  // Keys for caching playback position
  static const String _positionPrefix = 'yt_position_';
  static const String _durationPrefix = 'yt_duration_';
  static const String _completedPrefix = 'yt_completed_';

  // Constructor
  YouTubeService({
    required DatabaseService databaseService,
    required ContentService contentService,
  }) :
        _databaseService = databaseService,
        _contentService = contentService;

  // Create a YouTube player controller for a video
  YoutubePlayerController createController(
      String videoId, {
        bool autoPlay = true,
        bool mute = false,
        YoutubePlayerFlags? flags,
      }) {
    return YoutubePlayerController(
      initialVideoId: videoId,
      flags: flags ??
          YoutubePlayerFlags(
            autoPlay: autoPlay,
            mute: mute,
            disableDragSeek: false, // Allow seeking
            loop: false,
            isLive: false,
            forceHD: false,
            enableCaption: true,
          ),
    );
  }

  // Check if video was partially watched
  Future<int> getPlaybackPosition(String videoId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_positionPrefix + videoId) ?? 0;
  }

  // Save video playback position
  Future<void> savePlaybackPosition(String videoId, int position) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_positionPrefix + videoId, position);
  }

  // Save video duration
  Future<void> saveVideoDuration(String videoId, int duration) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_durationPrefix + videoId, duration);
  }

  // Get video duration
  Future<int> getVideoDuration(String videoId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_durationPrefix + videoId) ?? 0;
  }

  // Mark video as completed
  Future<void> markVideoAsCompleted(String videoId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_completedPrefix + videoId, true);
  }

  // Check if video was completed
  Future<bool> isVideoCompleted(String videoId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_completedPrefix + videoId) ?? false;
  }

  // Reset video playback data
  Future<void> resetVideoPlaybackData(String videoId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_positionPrefix + videoId);
    await prefs.remove(_completedPrefix + videoId);
  }

  // Track video playback
  Future<void> trackPlayback({
    required String videoId,
    required String contentId,
    required String userId,
    required int position,
    required int duration,
  }) async {
    // Save current position
    await savePlaybackPosition(videoId, position);

    // Save video duration
    await saveVideoDuration(videoId, duration);

    // Check if video is mostly complete (viewed at least 80%)
    bool isComplete = position >= (duration * 0.8);

    // If video is complete and wasn't marked as complete before
    if (isComplete && !(await isVideoCompleted(videoId))) {
      // Mark video as completed
      await markVideoAsCompleted(videoId);

      // Update progress in database if online
      if (await _isOnline()) {
        // Get progress ID
        final progress = await _databaseService.getUserContentProgress(userId, contentId);

        if (progress != null) {
          // Update watch time
          await _databaseService.updateWatchTime(progress.id, position);

          // If not already completed, mark as completed
          if (!progress.isCompleted) {
            // Get content to determine points value
            final content = await _databaseService.getContent(contentId);

            if (content != null) {
              // Award points based on content value or default
              final pointsToAward = content.pointsValue > 0
                  ? content.pointsValue
                  : 10; // Default points

              // Complete progress and award points
              await _databaseService.completeContentProgress(progress.id, pointsToAward);

              // Add to completed lessons and update user points
              await _databaseService.addCompletedLesson(userId, contentId);
              await _databaseService.updateUserPoints(userId, pointsToAward);

              // Check for unlocked achievements
              await _databaseService.checkAndAwardAchievements(userId);
            }
          }
        }
      }
    } else {
      // Just update watch time if we're online
      if (await _isOnline()) {
        final progress = await _databaseService.getUserContentProgress(userId, contentId);

        if (progress != null) {
          await _databaseService.updateWatchTime(progress.id, position);
        }
      }
    }
  }

  // Check if device is online
  Future<bool> _isOnline() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  // Get YouTube video thumbnail
  Future<String?> getVideoThumbnail(String videoId) async {
    // Check local cache first
    final cachedThumbnail = await _contentService.getCachedYouTubeThumbnail(videoId);

    if (cachedThumbnail != null) {
      return cachedThumbnail;
    }

    // If online and not in cache, get from YouTube API
    if (await _isOnline()) {
      final details = await _contentService.getYouTubeVideoDetails(videoId);
      return details?['thumbnailUrl'];
    }

    // Default thumbnail if all else fails
    return 'https://img.youtube.com/vi/$videoId/0.jpg';
  }

  // Check if a video can be played offline
  Future<bool> canPlayOffline(String videoId) async {
    // Check if video is available offline (would be cached by YouTube plugin)
    return await _contentService.isVideoAvailableOffline(videoId);
  }

  // Handle YouTube player errors
  void handlePlayerError(String videoId, String error) {
    // Log error for reporting
    print('YouTube player error for video $videoId: $error');
  }

  // Calculate completion percentage
  double calculateCompletion(int position, int duration) {
    if (duration <= 0) return 0.0;
    return (position / duration) * 100;
  }

  // Check if we should award points based on watching time
  bool shouldAwardPoints(int position, int duration) {
    return position >= (duration * 0.8);
  }

  // Get formatted duration string (mm:ss)
  String formatDuration(int seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;

    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // Get a default configuration for the YouTube player
  Map<String, dynamic> getDefaultPlayerConfig() {
    return {
      'showControls': true,
      'showFullscreenButton': true,
      'enableCaption': true,
      'disableDragSeek': false,
    };
  }

  // Create YouTube player with position tracking
  Widget createTrackedPlayer({
    required String videoId,
    required String contentId,
    required String userId,
    bool autoPlay = true,
    bool mute = false,
    int startAtSeconds = 0,
    Function(bool)? onCompleted,
  }) {
    // Implementation would depend on UI package
    // For MVP, would return a YouTubePlayer widget with necessary callbacks
    // This is a scaffold for implementation
    /*
    // Create controller
    final controller = createController(
      videoId,
      autoPlay: autoPlay,
      mute: mute,
    );

    // Set initial position if needed
    if (startAtSeconds > 0) {
      controller.seekTo(Duration(seconds: startAtSeconds));
    }

    // Implement position tracking
    Timer? positionTimer;

    // Start tracking timer
    positionTimer = Timer.periodic(Duration(seconds: 5), (timer) async {
      if (controller.value.isPlaying) {
        int position = controller.value.position.inSeconds;
        int duration = controller.value.metaData.duration.inSeconds;

        // Track playback
        await trackPlayback(
          videoId: videoId,
          contentId: contentId,
          userId: userId,
          position: position,
          duration: duration,
        );

        // Check if video is complete
        bool isComplete = shouldAwardPoints(position, duration);
        if (isComplete && onCompleted != null) {
          onCompleted(true);
        }
      }
    });

    // Return YouTube player
    return YouTubePlayer(
      controller: controller,
      showVideoProgressIndicator: true,
      progressIndicatorColor: Colors.red,
      onReady: () {
        // Player is ready
        if (startAtSeconds > 0) {
          controller.seekTo(Duration(seconds: startAtSeconds));
        }
      },
      onEnded: (metaData) async {
        // Video ended
        await trackPlayback(
          videoId: videoId,
          contentId: contentId,
          userId: userId,
          position: metaData.duration.inSeconds,
          duration: metaData.duration.inSeconds,
        );

        if (onCompleted != null) {
          onCompleted(true);
        }

        // Cancel timer
        positionTimer?.cancel();
      },
      // [Additional customization options]
    );
    */

    // For now, return a placeholder
    return Container(); // Return actual widget in implementation
  }
}
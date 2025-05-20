import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/content_model.dart';

class ContentService {
  // Constants for caching
  static const String _cachedContentPrefix = 'cached_content_';
  static const String _cachedThumbnailPrefix = 'cached_thumbnail_';
  static const Duration _cacheDuration = Duration(days: 7);

  // YouTube API related constants
  static const String _youtubeApiBaseUrl = 'https://www.googleapis.com/youtube/v3';
  // NOTE: In production, replace with real API key and secure it properly
  // For MVP, we'll use this placeholder approach
  static const String _youtubeApiKey = 'YOUR_YOUTUBE_API_KEY';

  // Connectivity check for offline mode
  Future<bool> isOnline() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  // Cache content data locally
  Future<void> cacheContent(ContentModel content) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _cachedContentPrefix + content.id;
    final contentJson = jsonEncode(content.toMap());

    await prefs.setString(key, contentJson);
    await prefs.setString('${key}_timestamp', DateTime.now().toIso8601String());
  }

  // Get cached content
  Future<ContentModel?> getCachedContent(String contentId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _cachedContentPrefix + contentId;

    final contentJson = prefs.getString(key);
    final timestampStr = prefs.getString('${key}_timestamp');

    if (contentJson == null || timestampStr == null) {
      return null;
    }

    final timestamp = DateTime.parse(timestampStr);
    final now = DateTime.now();

    // Check if cache is expired
    if (now.difference(timestamp) > _cacheDuration) {
      // Cache expired, clean it up
      await prefs.remove(key);
      await prefs.remove('${key}_timestamp');
      return null;
    }

    try {
      Map<String, dynamic> contentMap = jsonDecode(contentJson);

      // We need to add the ID as it's not part of the toMap result
      contentMap['id'] = contentId;

      // Convert timestamps back to DateTime
      if (contentMap['createdAt'] != null) {
        contentMap['createdAt'] = DateTime.parse(contentMap['createdAt']);
      }

      if (contentMap['updatedAt'] != null) {
        contentMap['updatedAt'] = DateTime.parse(contentMap['updatedAt']);
      }

      return ContentModel(
        id: contentId,
        title: contentMap['title'] ?? '',
        description: contentMap['description'] ?? '',
        contentType: ContentType.values.firstWhere(
              (e) => e.toString() == 'ContentType.${contentMap['contentType']}',
          orElse: () => ContentType.mixed,
        ),
        youtubeVideoId: contentMap['youtubeVideoId'] ?? '',
        slideUrls: List<String>.from(contentMap['slideUrls'] ?? []),
        slideContents: List<String>.from(contentMap['slideContents'] ?? []),
        pointsValue: contentMap['pointsValue'] ?? 0,
        moduleId: contentMap['moduleId'] ?? '',
        sequenceNumber: contentMap['sequenceNumber'] ?? 0,
        estimatedDuration: contentMap['estimatedDuration'] ?? 0,
        isActive: contentMap['isActive'] ?? true,
        createdAt: contentMap['createdAt'] ?? DateTime.now(),
        updatedAt: contentMap['updatedAt'] ?? DateTime.now(),
        isDownloadable: contentMap['isDownloadable'] ?? true,
        metadata: contentMap['metadata'] ?? {},
      );
    } catch (e) {
      // Error parsing cached content, clean up and return null
      await prefs.remove(key);
      await prefs.remove('${key}_timestamp');
      return null;
    }
  }

  // Cache YouTube video thumbnail
  Future<void> cacheYouTubeThumbnail(String videoId, String thumbnailUrl) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _cachedThumbnailPrefix + videoId;

    await prefs.setString(key, thumbnailUrl);
    await prefs.setString('${key}_timestamp', DateTime.now().toIso8601String());
  }

  // Get cached YouTube thumbnail URL
  Future<String?> getCachedYouTubeThumbnail(String videoId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _cachedThumbnailPrefix + videoId;

    final thumbnailUrl = prefs.getString(key);
    final timestampStr = prefs.getString('${key}_timestamp');

    if (thumbnailUrl == null || timestampStr == null) {
      return null;
    }

    final timestamp = DateTime.parse(timestampStr);
    final now = DateTime.now();

    // Check if cache is expired
    if (now.difference(timestamp) > _cacheDuration) {
      // Cache expired, clean it up
      await prefs.remove(key);
      await prefs.remove('${key}_timestamp');
      return null;
    }

    return thumbnailUrl;
  }

  // Get YouTube video details (title, description, thumbnail)
  Future<Map<String, dynamic>?> getYouTubeVideoDetails(String videoId) async {
    // First check if we're online
    if (!await isOnline()) {
      return null;
    }

    try {
      final response = await http.get(
        Uri.parse(
          '$_youtubeApiBaseUrl/videos?part=snippet,contentDetails&id=$videoId&key=$_youtubeApiKey',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['items'] != null && data['items'].isNotEmpty) {
          final item = data['items'][0];
          final snippet = item['snippet'];
          final contentDetails = item['contentDetails'];

          // Parse duration string (PT1H2M3S format)
          String duration = contentDetails['duration'];
          int durationMinutes = _parseDuration(duration);

          // Get highest quality thumbnail available
          String? thumbnailUrl;
          if (snippet['thumbnails'] != null) {
            final thumbnails = snippet['thumbnails'];

            if (thumbnails['maxres'] != null) {
              thumbnailUrl = thumbnails['maxres']['url'];
            } else if (thumbnails['high'] != null) {
              thumbnailUrl = thumbnails['high']['url'];
            } else if (thumbnails['medium'] != null) {
              thumbnailUrl = thumbnails['medium']['url'];
            } else if (thumbnails['default'] != null) {
              thumbnailUrl = thumbnails['default']['url'];
            }
          }

          // Cache the thumbnail URL
          if (thumbnailUrl != null) {
            await cacheYouTubeThumbnail(videoId, thumbnailUrl);
          }

          return {
            'title': snippet['title'],
            'description': snippet['description'],
            'thumbnailUrl': thumbnailUrl,
            'durationMinutes': durationMinutes,
            'publishedAt': snippet['publishedAt'],
          };
        }
      }

      return null;
    } catch (e) {
      // Network error or API failure
      return null;
    }
  }

  // Helper method to parse ISO 8601 duration string
  int _parseDuration(String duration) {
    // Parse ISO 8601 duration (e.g., PT1H2M3S)
    final hours = RegExp(r'(\d+)H').firstMatch(duration)?.group(1);
    final minutes = RegExp(r'(\d+)M').firstMatch(duration)?.group(1);
    final seconds = RegExp(r'(\d+)S').firstMatch(duration)?.group(1);

    int totalMinutes = 0;

    if (hours != null) {
      totalMinutes += int.parse(hours) * 60;
    }

    if (minutes != null) {
      totalMinutes += int.parse(minutes);
    }

    if (seconds != null) {
      totalMinutes += (int.parse(seconds) / 60).ceil();
    }

    return totalMinutes;
  }

  // Fetch fallback content when YouTube is not accessible
  Future<Map<String, dynamic>?> getFallbackContent(String contentId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'fallback_content_$contentId';

    final fallbackContentJson = prefs.getString(key);
    if (fallbackContentJson == null) {
      return null;
    }

    try {
      return jsonDecode(fallbackContentJson);
    } catch (e) {
      return null;
    }
  }

  // Save fallback content for when YouTube is not accessible
  Future<void> saveFallbackContent(String contentId, Map<String, dynamic> fallbackContent) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'fallback_content_$contentId';

    await prefs.setString(key, jsonEncode(fallbackContent));
  }

  // Check if a video is available offline
  Future<bool> isVideoAvailableOffline(String videoId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('offline_video_$videoId');
  }

  // Mark video as available offline
  Future<void> markVideoAsOffline(String videoId, bool isAvailable) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'offline_video_$videoId';

    if (isAvailable) {
      await prefs.setBool(key, true);
    } else {
      await prefs.remove(key);
    }
  }

  // Calculate points based on watch time
  int calculatePointsForWatchTime(int totalDurationSeconds, int watchedSeconds) {
    // Only award points if watched at least 80% of the video
    double completionRatio = watchedSeconds / totalDurationSeconds;

    if (completionRatio >= 0.8) {
      return 100; // Award full points for watching most of the video
    } else if (completionRatio >= 0.5) {
      return 50; // Award partial points for watching at least half
    } else {
      return 0; // No points for watching less than half
    }
  }

  // Get the YouTube player configuration for the given video ID
  Map<String, dynamic> getYouTubePlayerConfig(String videoId) {
    return {
      'videoId': videoId,
      'startAt': 0, // Default to starting at the beginning
      'showControls': true,
      'showFullscreenButton': true,
      'showProgressBar': true,
    };
  }

  // Get offline content bundles that need to be downloaded
  Future<List<String>> getPendingOfflineContentIds() async {
    final prefs = await SharedPreferences.getInstance();
    final pendingDownloadsJson = prefs.getString('pending_offline_content');

    if (pendingDownloadsJson == null) {
      return [];
    }

    try {
      List<dynamic> pendingList = jsonDecode(pendingDownloadsJson);
      return pendingList.cast<String>();
    } catch (e) {
      return [];
    }
  }

  // Add content to offline download queue
  Future<void> addToOfflineQueue(String contentId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> pendingDownloads = await getPendingOfflineContentIds();

    if (!pendingDownloads.contains(contentId)) {
      pendingDownloads.add(contentId);
      await prefs.setString('pending_offline_content', jsonEncode(pendingDownloads));
    }
  }

  // Remove content from offline download queue
  Future<void> removeFromOfflineQueue(String contentId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> pendingDownloads = await getPendingOfflineContentIds();

    pendingDownloads.remove(contentId);
    await prefs.setString('pending_offline_content', jsonEncode(pendingDownloads));
  }

  // Get saved video position (in seconds) for resuming playback
  Future<int> getSavedVideoPosition(String videoId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'video_position_$videoId';

    return prefs.getInt(key) ?? 0;
  }

  // Save video position for resuming later
  Future<void> saveVideoPosition(String videoId, int positionSeconds) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'video_position_$videoId';

    await prefs.setInt(key, positionSeconds);
  }

  // Check if user needs to resume video or start from beginning
  Future<bool> shouldResumeVideo(String videoId) async {
    final int savedPosition = await getSavedVideoPosition(videoId);

    // If video was watched for at least 30 seconds but not completed, offer to resume
    return savedPosition >= 30;
  }

  // Reset saved video position (after completion or manual reset)
  Future<void> resetVideoPosition(String videoId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'video_position_$videoId';

    await prefs.remove(key);
  }

  // Verify video completion for point awarding
  Future<bool> verifyVideoCompletion(String videoId, int watchedSeconds) async {
    try {
      // If we're offline, use cached data
      if (!await isOnline()) {
        final prefs = await SharedPreferences.getInstance();
        final key = 'video_duration_$videoId';
        final duration = prefs.getInt(key);

        if (duration == null) {
          return false; // Can't verify without duration
        }

        // Consider watched if at least 80% complete
        return watchedSeconds >= (duration * 0.8);
      }

      // If online, fetch the video duration from YouTube API
      final details = await getYouTubeVideoDetails(videoId);

      if (details == null) {
        return false;
      }

      int durationMinutes = details['durationMinutes'] ?? 0;
      int durationSeconds = durationMinutes * 60;

      // Cache the duration for offline use
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('video_duration_$videoId', durationSeconds);

      // Consider watched if at least 80% complete
      return watchedSeconds >= (durationSeconds * 0.8);
    } catch (e) {
      return false;
    }
  }

  // Check if data usage warning is needed (for videos over certain size)
  Future<bool> shouldWarnAboutDataUsage(String videoId) async {
    // Check user preference first
    final prefs = await SharedPreferences.getInstance();
    final neverWarn = prefs.getBool('never_warn_data_usage') ?? false;

    if (neverWarn) {
      return false;
    }

    // Check if this is a high definition video
    try {
      final details = await getYouTubeVideoDetails(videoId);

      if (details == null) {
        return false;
      }

      // Estimate data usage based on video duration
      // Rough estimate: HD video (720p) = ~3MB per minute
      int durationMinutes = details['durationMinutes'] ?? 0;

      // Warn if video is longer than 10 minutes (approximately 30MB)
      return durationMinutes > 10;
    } catch (e) {
      return false;
    }
  }

  // Check if user is on WiFi (to determine if pre-downloading is allowed)
  Future<bool> isOnWiFi() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult == ConnectivityResult.wifi;
  }

  // Check if content should be auto-downloaded based on user settings
  Future<bool> shouldAutoDownload() async {
    // Check user preferences
    final prefs = await SharedPreferences.getInstance();
    final wifiOnly = prefs.getBool('download_wifi_only') ?? true;

    if (wifiOnly) {
      return await isOnWiFi();
    }

    return true;
  }
}
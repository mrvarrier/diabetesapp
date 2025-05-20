// File: lib/data/services/youtube_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/constants.dart';

class YouTubeService {
  // YouTube API key would be stored in a secure environment variable in production
  // For this MVP, we'll use a placeholder
  final String _apiKey = 'YOUR_YOUTUBE_API_KEY';

  // Cache duration
  final Duration _cacheDuration = AppConstants.cacheDuration;

  // Get video info
  Future<Map<String, dynamic>?> getVideoInfo(String videoId) async {
    try {
      // Check cache first
      final cachedInfo = await _getCachedVideoInfo(videoId);
      if (cachedInfo != null) {
        return cachedInfo;
      }

      // If not in cache, fetch from API
      final response = await http.get(
        Uri.parse(
            '${AppConstants.youtubeApiBaseUrl}/videos?part=snippet,contentDetails,statistics&id=$videoId&key=$_apiKey'
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['items'] != null && data['items'].isNotEmpty) {
          final videoInfo = data['items'][0];

          // Cache the result
          await _cacheVideoInfo(videoId, videoInfo);

          return videoInfo;
        }
      }

      return null;
    } catch (e) {
      return null; // Return null on error for graceful degradation
    }
  }

  // Get video duration in seconds
  Future<int?> getVideoDuration(String videoId) async {
    try {
      final videoInfo = await getVideoInfo(videoId);
      if (videoInfo != null &&
          videoInfo['contentDetails'] != null &&
          videoInfo['contentDetails']['duration'] != null) {

        final isoDuration = videoInfo['contentDetails']['duration'];
        return _parseIsoDuration(isoDuration);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // Get video thumbnail
  Future<String?> getVideoThumbnail(String videoId) async {
    try {
      final videoInfo = await getVideoInfo(videoId);
      if (videoInfo != null &&
          videoInfo['snippet'] != null &&
          videoInfo['snippet']['thumbnails'] != null) {

        final thumbnails = videoInfo['snippet']['thumbnails'];

        // Try to get the high quality thumbnail, fall back to others if not available
        if (thumbnails['high'] != null) {
          return thumbnails['high']['url'];
        } else if (thumbnails['medium'] != null) {
          return thumbnails['medium']['url'];
        } else if (thumbnails['default'] != null) {
          return thumbnails['default']['url'];
        }
      }

      // If all else fails, return the default thumbnail URL pattern
      return 'https://img.youtube.com/vi/$videoId/0.jpg';
    } catch (e) {
      // Fallback to the default thumbnail URL pattern
      return 'https://img.youtube.com/vi/$videoId/0.jpg';
    }
  }

  // Calculate points based on watch time
  int calculatePoints(
      int watchedDuration,
      int totalDuration,
      int basePoints,
      {int minPercentage = 80}
      ) {
    if (totalDuration <= 0) return 0;

    final watchPercentage = (watchedDuration / totalDuration) * 100;

    // If watched less than minimum requirement, no points
    if (watchPercentage < minPercentage) {
      return 0;
    }

    // Award points proportionally, with bonus for full watch
    if (watchPercentage >= 99) {
      return basePoints; // Full points for complete watch
    } else {
      // Proportional points for partial watch (meeting minimum threshold)
      final pointRatio = (watchPercentage - minPercentage) / (100 - minPercentage);
      return (basePoints * pointRatio).round();
    }
  }

  // Cache video info to reduce API calls
  Future<void> _cacheVideoInfo(String videoId, Map<String, dynamic> videoInfo) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'youtube_video_$videoId';

      // Store the video info and cache timestamp
      final cacheData = {
        'info': videoInfo,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      await prefs.setString(cacheKey, json.encode(cacheData));
    } catch (e) {
      // Ignore caching errors
    }
  }

  // Get cached video info if available and not expired
  Future<Map<String, dynamic>?> _getCachedVideoInfo(String videoId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'youtube_video_$videoId';

      final cachedData = prefs.getString(cacheKey);
      if (cachedData != null) {
        final data = json.decode(cachedData);
        final timestamp = data['timestamp'];

        // Check if cache is still valid
        final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
        if (cacheAge < _cacheDuration.inMilliseconds) {
          return data['info'];
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // Parse ISO 8601 duration format to seconds
  int _parseIsoDuration(String isoDuration) {
    // Remove PT prefix
    String duration = isoDuration.substring(2);

    int hours = 0;
    int minutes = 0;
    int seconds = 0;

    // Hours
    int hourIndex = duration.indexOf('H');
    if (hourIndex != -1) {
      hours = int.parse(duration.substring(0, hourIndex));
      duration = duration.substring(hourIndex + 1);
    }

    // Minutes
    int minuteIndex = duration.indexOf('M');
    if (minuteIndex != -1) {
      minutes = int.parse(duration.substring(0, minuteIndex));
      duration = duration.substring(minuteIndex + 1);
    }

    // Seconds
    int secondIndex = duration.indexOf('S');
    if (secondIndex != -1) {
      seconds = int.parse(duration.substring(0, secondIndex));
    }

    return hours * 3600 + minutes * 60 + seconds;
  }

  // Check if video exists and is available
  Future<bool> isVideoAvailable(String videoId) async {
    try {
      final videoInfo = await getVideoInfo(videoId);
      return videoInfo != null;
    } catch (e) {
      return false;
    }
  }
}
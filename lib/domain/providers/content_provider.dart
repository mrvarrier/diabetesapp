// File: lib/domain/providers/content_provider.dart

import 'package:flutter/foundation.dart';
import '../../data/models/content_model.dart';
import '../../data/services/database_service.dart';
import '../../data/services/local_storage_service.dart';
import '../../data/services/youtube_service.dart';

class ContentProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final LocalStorageService _localStorageService = LocalStorageService();
  final YouTubeService _youtubeService = YouTubeService();

  List<Content> _contents = [];
  Content? _selectedContent;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Content> get contents => _contents;
  Content? get selectedContent => _selectedContent;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load content for a specific user
  Future<void> loadContentForUser(String userId, String diabetesType, String treatmentMethod) async {
    _setLoading(true);

    try {
      // Try to get contents from local storage first
      final localContents = await _localStorageService.getAllContents();

      if (localContents.isNotEmpty) {
        // Filter contents based on user's diabetes type and treatment method
        _contents = localContents
            .where((content) => content.isApplicableTo(diabetesType, treatmentMethod))
            .toList();

        // Sort by order
        _contents.sort((a, b) => a.order.compareTo(b.order));

        notifyListeners();
      }

      // Try to get updated contents from Firestore
      try {
        final remoteContents = await _databaseService.getContentsByRequirements(
          diabetesType: diabetesType,
          treatmentMethod: treatmentMethod,
        );

        if (remoteContents.isNotEmpty) {
          // Save to local storage
          await _localStorageService.saveContents(remoteContents);

          // Update in-memory contents
          _contents = remoteContents;

          // Sort by order
          _contents.sort((a, b) => a.order.compareTo(b.order));

          notifyListeners();
        }
      } catch (e) {
        // If remote fetch fails, continue with local contents
        // We already set _contents from local storage
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Get content by ID
  Future<Content?> getContentById(String contentId) async {
    try {
      // Check if it's already in the loaded contents
      final existingContent = _contents.firstWhere(
            (content) => content.id == contentId,
        orElse: () => null as Content, // This will cause an error if no content is found
      );

      if (existingContent != null) {
        return existingContent;
      }

      // Try to get from local storage
      final localContent = await _localStorageService.getContentById(contentId);
      if (localContent != null) {
        return localContent;
      }

      // Try to get from Firestore
      final remoteContent = await _databaseService.getContentById(contentId);
      if (remoteContent != null) {
        // Save to local storage
        await _localStorageService.saveContents([remoteContent]);
        return remoteContent;
      }

      return null;
    } catch (e) {
      _error = e.toString();
      return null;
    }
  }

  // Set selected content
  void setSelectedContent(Content content) {
    _selectedContent = content;
    notifyListeners();
  }

  // Clear selected content
  void clearSelectedContent() {
    _selectedContent = null;
    notifyListeners();
  }

  // Get YouTube thumbnail for a content item
  Future<String?> getYouTubeThumbnail(String videoId) async {
    try {
      return await _youtubeService.getVideoThumbnail(videoId);
    } catch (e) {
      return null;
    }
  }

  // Get video duration
  Future<Duration?> getVideoDuration(String videoId) async {
    try {
      final durationInSeconds = await _youtubeService.getVideoDuration(videoId);
      if (durationInSeconds != null) {
        return Duration(seconds: durationInSeconds);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Calculate points based on watch time
  int calculateVideoPoints(int watchedSeconds, int totalSeconds, int basePoints) {
    return _youtubeService.calculatePoints(
      watchedSeconds,
      totalSeconds,
      basePoints,
    );
  }

  // Check if video exists and is available
  Future<bool> isVideoAvailable(String videoId) async {
    try {
      return await _youtubeService.isVideoAvailable(videoId);
    } catch (e) {
      return false;
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
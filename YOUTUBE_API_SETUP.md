# YouTube API Integration Guide

The DiabetesBuddy app uses YouTube as its video content provider. This guide will help you set up and configure the YouTube Data API for integration with the app.

## Prerequisites

- Google account for YouTube API access
- Google Cloud Platform project (can be the same as Firebase project)
- Basic understanding of APIs and HTTP requests

## Step 1: Create a Google Cloud Platform Project

Skip this step if you're using the same project as Firebase.

1. Go to the [Google Cloud Console](https://console.cloud.google.com/)
2. Click "Create Project"
3. Enter "DiabetesBuddy" as the project name
4. Choose your organization (if applicable)
5. Click "Create"

## Step 2: Enable the YouTube Data API

1. In the Google Cloud Console, select your project
2. Navigate to "APIs & Services" > "Library"
3. Search for "YouTube Data API v3"
4. Click on the API
5. Click "Enable"

## Step 3: Create API Credentials

1. Navigate to "APIs & Services" > "Credentials"
2. Click "Create Credentials" > "API Key"
3. Copy the generated API key
4. Click "Edit API key" to set restrictions (recommended for security)
5. Under "Application restrictions", select "Android apps" and/or "iOS apps"
6. Add your app's package name or bundle ID
7. Under "API restrictions", select "Restrict key" and choose "YouTube Data API v3"
8. Click "Save"

## Step 4: Set Up API Key in the App

1. Open `lib/services/content_service.dart`
2. Locate the `_youtubeApiKey` constant:

```dart
// Before
static const String _youtubeApiKey = 'YOUR_YOUTUBE_API_KEY';

// After
static const String _youtubeApiKey = 'AIza...'; // Your actual API key
```

For better security in production:

1. Use environment variables or a secure, non-versioned configuration file
2. Consider using Firebase Remote Config to store and update API keys

## Step 5: Set Up API Access with Quotas

The YouTube Data API has quotas to limit usage. For DiabetesBuddy, configure appropriate quotas:

1. In Google Cloud Console, go to "APIs & Services" > "YouTube Data API v3"
2. Click "Manage"
3. Go to "Quotas"
4. Review the default quotas:
    - Default is 10,000 units per day
    - Each API operation costs different units (e.g., video search costs 100 units)
5. Request additional quota if needed for your expected user base

## Step 6: Understanding YouTube API Endpoints

The app uses these main API endpoints:

1. **Videos**: Get video details, duration, and status
    - Cost: 1 unit per request
    - Example: `GET https://www.googleapis.com/youtube/v3/videos?part=snippet,contentDetails&id=VIDEO_ID&key=YOUR_API_KEY`

2. **Search**: Find related content
    - Cost: 100 units per request
    - Example: `GET https://www.googleapis.com/youtube/v3/search?part=snippet&q=diabetes education&type=video&key=YOUR_API_KEY`

3. **Captions**: Get transcript data (if enabled)
    - Cost: 2 units per request
    - Example: `GET https://www.googleapis.com/youtube/v3/captions?part=snippet&videoId=VIDEO_ID&key=YOUR_API_KEY`

## Step 7: Handle YouTube Player Setup in Flutter

The app uses the `youtube_player_flutter` package to display videos:

1. Ensure the package is properly added to your `pubspec.yaml`:

```yaml
dependencies:
  youtube_player_flutter: ^8.1.2
```

2. Test the YouTube player implementation in your app
3. Run the app and verify the video player loads correctly
4. Test with at least one offline video to ensure caching works

## Step 8: Optimize YouTube API Usage

To minimize API costs and stay within quotas:

1. **Cache video details**: Store video metadata locally to reduce API calls
2. **Batch requests**: When possible, request multiple video details in a single API call
3. **Load videos on demand**: Only fetch metadata when a user views or downloads content
4. **Implement exponential backoff**: Handle rate limiting by retrying with increasing delays
5. **Monitor quota usage**: Set up alerts in Google Cloud Console for quota thresholds

## Step 9: YouTube Player Features Implementation

Ensure these features are working in your implementation:

1. **Progress tracking**: Monitor watch time to award points
2. **Playback position saving**: Allow users to resume where they left off
3. **Offline playback**: Cache videos for offline viewing
4. **Playback controls**: Ensure play, pause, seek, and fullscreen work properly
5. **Error handling**: Gracefully handle video loading errors and availability issues

## Step 10: Content Guidelines and Restrictions

When using YouTube as a content source, be aware of:

1. **Terms of Service**: Ensure compliance with YouTube's Terms of Service
2. **Content filtering**: Implement appropriate content filtering for educational content
3. **Age restrictions**: Handle age-restricted content appropriately
4. **Copyright**: Use only properly licensed content for education
5. **Embedding**: Follow YouTube's embedding policies

## Troubleshooting Common Issues

1. **API Key Invalid**:
    - Verify the key is correct and has not been restricted incorrectly
    - Check that the API is enabled in Google Cloud Console
    - Ensure the project is in good standing (billing status if applicable)

2. **Quota Exceeded**:
    - Implement local caching to reduce API calls
    - Stagger or batch API requests
    - Request quota increase if necessary

3. **Video Unavailable**:
    - Verify the video exists and is public
    - Check for region restrictions
    - Implement fallback content for unavailable videos

4. **Player Loading Issues**:
    - Check network connectivity
    - Verify YouTube API service status
    - Ensure proper initialization of the player widget

5. **Video Playback Issues**:
    - Test on multiple devices and network conditions
    - Implement quality selection options
    - Check for device compatibility issues

## Code Examples

### Checking Video Details

```dart
Future<Map<String, dynamic>?> getYouTubeVideoDetails(String videoId) async {
  try {
    final response = await http.get(
      Uri.parse(
        'https://www.googleapis.com/youtube/v3/videos?part=snippet,contentDetails&id=$videoId&key=$_youtubeApiKey',
      ),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      if (data['items'] != null && data['items'].isNotEmpty) {
        final item = data['items'][0];
        final snippet = item['snippet'];
        final contentDetails = item['contentDetails'];
        
        // Parse duration
        String duration = contentDetails['duration'];
        int durationMinutes = _parseDuration(duration);
        
        return {
          'title': snippet['title'],
          'description': snippet['description'],
          'thumbnailUrl': snippet['thumbnails']['high']['url'],
          'durationMinutes': durationMinutes,
          'publishedAt': snippet['publishedAt'],
        };
      }
    }
    
    return null;
  } catch (e) {
    print('YouTube API error: $e');
    return null;
  }
}
```

### Creating YouTube Player

```dart
YoutubePlayerController createController(String videoId) {
  return YoutubePlayerController(
    initialVideoId: videoId,
    flags: YoutubePlayerFlags(
      autoPlay: true,
      mute: false,
      disableDragSeek: false,
      loop: false,
      isLive: false,
      forceHD: false,
      enableCaption: true,
    ),
  );
}
```

### Tracking Video Progress

```dart
Future<void> trackPlayback({
  required String videoId,
  required String contentId,
  required String userId,
  required int position,
  required int duration,
}) async {
  // Save current position
  await savePlaybackPosition(videoId, position);
  
  // Check if video is mostly complete (viewed at least 80%)
  bool isComplete = position >= (duration * 0.8);
  
  if (isComplete) {
    // Update progress in database
    final progress = await _databaseService.getUserContentProgress(userId, contentId);
    
    if (progress != null) {
      await _databaseService.completeContentProgress(progress.id, 10); // Award points
    }
  }
}
```

## Resource Links

- [YouTube Data API Documentation](https://developers.google.com/youtube/v3/docs)
- [YouTube Player Flutter Package](https://pub.dev/packages/youtube_player_flutter)
- [YouTube Terms of Service](https://www.youtube.com/t/terms)
- [Google Cloud API Dashboard](https://console.cloud.google.com/apis/dashboard)
- [YouTube API Sample Code](https://github.com/youtube/api-samples)
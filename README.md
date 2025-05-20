# DiabetesEdu - Flutter Diabetes Education App

DiabetesEdu is a gamified diabetes education app built with Flutter. It helps patients learn about diabetes through videos, slides, and quizzes, following an engagement model similar to Duolingo.

## Features

- **User Authentication**: Register, login, and profile management
- **Custom Learning Plans**: Personalized based on diabetes type and treatment approach
- **Gamification**: Points system, achievements, and streaks
- **Content Delivery**: YouTube videos and slides with progress tracking
- **Quiz System**: Interactive quizzes with scoring and feedback
- **Progress Tracking**: Visual reports on learning progress
- **Offline Support**: Core functionality works offline with synchronization
- **Admin Panel**: Manage content, quizzes, and user data

## Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK
- Android Studio / VS Code with Flutter extensions
- Firebase account

### Setup Instructions

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/diabetes-edu.git
   cd diabetes-edu
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
    - Create a new Firebase project at [firebase.google.com](https://firebase.google.com)
    - Enable Authentication (Email/Password)
    - Create a Firestore Database
    - Download and add the `google-services.json` file to `/android/app/`
    - Download and add the `GoogleService-Info.plist` file to `/ios/Runner/`

4. **YouTube API Setup**
    - Create a Google Cloud project
    - Enable the YouTube Data API v3
    - Create API credentials
    - Add your YouTube API key to `lib/data/services/youtube_service.dart`

5. **Run the app**
   ```bash
   flutter run
   ```

## Project Structure

The app is organized using a feature-based architecture:

```
lib/
│
├── main.dart                  # App entry point
├── app.dart                   # App configuration
│
├── config/                    # Configuration files
│   ├── routes.dart            # Route definitions
│   ├── theme.dart             # App theme configuration
│   └── constants.dart         # App constants
│
├── core/                      # Core utilities
│   ├── error/                 # Error handling
│   ├── network/               # Network utilities
│   └── utils/                 # Helper functions
│
├── data/                      # Data layer
│   ├── models/                # Data models
│   ├── repositories/          # Repositories implementation
│   └── services/              # Services for external APIs
│
├── domain/                    # Domain layer
│   ├── providers/             # State management providers
│   └── usecases/              # Business logic use cases
│
├── presentation/              # UI Layer
│   ├── common/                # Common widgets
│   ├── screens/               # App screens
│   └── widgets/               # Reusable widgets
│
└── localization/              # Internationalization
```

## Dependencies

The app uses the following main dependencies:

- **firebase_core, firebase_auth, cloud_firestore**: Firebase integration
- **provider**: State management
- **youtube_player_flutter**: YouTube video playback
- **shared_preferences**: Local storage
- **hive_flutter**: Offline database
- **flutter_local_notifications**: Local notifications
- **connectivity_plus**: Network connectivity checking
- **path_provider**: File system access

For a complete list, see the `pubspec.yaml` file.

## Firebase Collection Structure

The Firestore database has the following collections:

- **users**: User account information
- **contents**: Educational content (videos, slides)
- **quizzes**: Quiz questions and answers
- **progress**: User progress tracking
- **achievements**: Earned user achievements
- **feedback**: User feedback on content
- **plans**: Educational plan templates

## Initial Content Setup

For the MVP, you'll need to set up some initial content in Firestore:

1. Create at least 3 content documents in the `contents` collection:
   ```json
   {
     "title": "Introduction to Diabetes",
     "description": "Learn the basics of diabetes and its types",
     "contentType": "video",
     "order": 1,
     "youtubeVideoId": "YOUR_YOUTUBE_VIDEO_ID",
     "pointsToEarn": 10,
     "tags": ["basics", "introduction"],
     "requiredDiabetesTypes": [],
     "requiredTreatmentMethods": [],
     "createdAt": Timestamp,
     "updatedAt": Timestamp,
     "isActive": true
   }
   ```

2. Create corresponding quiz documents in the `quizzes` collection:
   ```json
   {
     "title": "Diabetes Basics Quiz",
     "description": "Test your knowledge of diabetes basics",
     "contentId": "CONTENT_DOC_ID",
     "questions": [
       {
         "id": "q1",
         "questionText": "What is diabetes?",
         "questionType": "multiple_choice",
         "options": [
           {
             "id": "a",
             "text": "A condition affecting only the lungs"
           },
           {
             "id": "b",
             "text": "A condition where blood glucose levels are too high"
           },
           {
             "id": "c",
             "text": "A viral infection"
           }
         ],
         "correctAnswers": ["b"],
         "explanation": "Diabetes is a condition where blood glucose levels are too high because the body cannot make or use insulin properly."
       }
     ],
     "passingScore": 60,
     "pointsPerQuestion": 5,
     "createdAt": Timestamp,
     "updatedAt": Timestamp,
     "isActive": true
   }
   ```

## Testing

### Manual Testing Checklist

- [ ] User Registration
- [ ] User Login
- [ ] Onboarding Flow
- [ ] Home Dashboard
- [ ] Video Playback
- [ ] Progress Tracking
- [ ] Quiz Functionality
- [ ] Achievement Unlocking
- [ ] Offline Mode
- [ ] Data Synchronization
- [ ] Settings Options
- [ ] Dark Mode
- [ ] Notifications

### Automated Testing

Basic widget tests are included in the `test/` directory. To run them:

```bash
flutter test
```

## Offline Functionality

The app implements offline functionality through:

1. Local data caching with Hive and SharedPreferences
2. YouTube video offline viewing capability
3. Background synchronization when online
4. Network connectivity monitoring

## Security Considerations

- User authentication is handled by Firebase Auth
- Medical data is stored securely and not shared with third parties
- Sensitive data is encrypted on-device
- Network calls use HTTPS
- The app implements proper error handling

## Deployment

### Android

1. Configure app details in `android/app/build.gradle`
2. Create a signing key:
   ```bash
   keytool -genkey -v -keystore ~/key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias key
   ```
3. Configure signing in `android/app/key.properties`
4. Build the APK:
   ```bash
   flutter build apk --release
   ```

### iOS

1. Configure app details in `ios/Runner/Info.plist`
2. Open the project in Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```
3. Configure signing in Xcode under Runner > Signing & Capabilities
4. Build the app:
   ```bash
   flutter build ios --release
   ```

## Future Enhancements

- Social sharing functionality
- Multiple language support
- More extensive admin dashboard
- Support for healthcare provider accounts
- Integration with health tracking apps/devices
- Forum/community features
- Advanced analytics dashboard

## Troubleshooting

### Common Issues

1. **Firebase connection issues**
    - Verify your `google-services.json` and `GoogleService-Info.plist` files
    - Check network connectivity
    - Ensure Firebase services are enabled

2. **YouTube player not working**
    - Verify your YouTube API key
    - Check if the device has YouTube app installed
    - Ensure the video ID is correct and the video is publicly accessible

3. **Offline mode issues**
    - Clear app data and cache
    - Ensure proper permissions are granted
    - Check if local storage is properly initialized

## Contributing

If you'd like to contribute to the project, please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.


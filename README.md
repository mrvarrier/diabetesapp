# DiabetesBuddy: Flutter Diabetes Education App

![DiabetesBuddy Logo](assets/images/logo.png)

A gamified diabetes education app built with Flutter that helps patients learn about diabetes management through interactive videos, slides, and quizzes.

## Features

- 🔐 **Authentication**: Secure login, registration and password reset
- 📚 **Personalized Education Plans**: Customized content based on diabetes type and treatment approach
- 🎮 **Gamification**: Points system, achievements, and daily streaks to encourage engagement
- 📽️ **Video Learning**: Integration with YouTube API for educational videos
- 📊 **Progress Tracking**: Detailed progress reports and analytics
- 📱 **Offline Support**: Core functionality works without internet connection
- 🏆 **Quiz System**: Knowledge assessment with immediate feedback
- 🔔 **Notifications**: Reminders to maintain streaks and engage with content
- 📄 **PDF Reports**: Downloadable progress reports

## Getting Started

### Prerequisites

- [Flutter](https://flutter.dev/docs/get-started/install) (2.0 or higher)
- [Firebase Account](https://firebase.google.com/) for authentication and database
- [YouTube API Key](https://developers.google.com/youtube/v3/getting-started) for video integration

### Installation

1. **Clone the repository**

```bash
git clone https://github.com/yourusername/diabetes_buddy.git
cd diabetes_buddy
```

2. **Install dependencies**

```bash
flutter pub get
```

3. **Configure Firebase**

- Create a new Firebase project
- Add Android and iOS apps to your Firebase project
- Download and add the configuration files (google-services.json for Android, GoogleService-Info.plist for iOS)
- Enable Authentication (Email/Password), Firestore Database, and Cloud Messaging

4. **Configure YouTube API**

- Replace the placeholder API key in `lib/services/content_service.dart` with your YouTube API key

5. **Run the app**

```bash
flutter run
```

## Project Structure

```
lib/
├── constants/                # App-wide constants
│   └── string_constants.dart # Text strings used throughout the app
│
├── models/                   # Data models
│   ├── user_model.dart       # User profile information
│   ├── content_model.dart    # Educational content
│   ├── quiz_model.dart       # Quiz questions and answers
│   └── ...                   # Other data models
│
├── navigation/               # Navigation configuration
│   └── app_router.dart       # Centralized navigation system
│
├── screens/                  # UI screens
│   ├── authentication/       # Login, register, etc.
│   ├── home/                 # Home screen and dashboard
│   ├── education/            # Content viewing screens
│   ├── progress/             # Progress tracking
│   ├── admin/                # Admin panel
│   ├── settings/             # App settings
│   └── widgets/              # Shared UI components
│
├── services/                 # Business logic and data services
│   ├── auth_service.dart     # Authentication logic
│   ├── database_service.dart # Database operations
│   ├── content_service.dart  # Content delivery
│   ├── points_service.dart   # Gamification points
│   ├── youtube_service.dart  # YouTube API integration
│   └── ...                   # Other services
│
├── theme/                    # Theme configuration
│   └── app_theme.dart        # Colors, typography, and styles
│
├── utils/                    # Utility functions and helpers
│
├── app.dart                  # Main app configuration
└── main.dart                 # App entry point
```

## Architecture

DiabetesBuddy follows a service-based architecture with clean separation of concerns:

1. **UI Layer** (Screens and Widgets): Responsible for displaying data and capturing user input
2. **Service Layer**: Contains business logic and serves as an intermediary between UI and data
3. **Data Layer**: Handles data persistence, network requests, and local storage
4. **Model Layer**: Defines the structure of data entities

The app uses **Provider** for state management, ensuring a unidirectional data flow and efficient rebuilds.

## Database Structure

DiabetesBuddy uses Firebase Firestore with the following collections:

- **users**: User profiles and progress tracking
- **content**: Educational materials including videos and slides
- **modules**: Collections of related content organized by topic
- **quizzes**: Knowledge assessment questions and answers
- **progress**: Tracking user interaction with content
- **achievements**: Gamification elements that can be unlocked
- **feedback**: User ratings and comments on content
- **analytics**: Usage statistics and engagement metrics

## Content Management

### Content Creation

The app supports two types of educational content:

1. **Video Content**: Linked from YouTube using video IDs
2. **Slide Content**: Text-based slides with simple formatting

Each piece of content belongs to a module and can have an associated quiz for knowledge assessment.

### Content Delivery

Content is delivered through:

- **YouTube Player**: For video content with progress tracking
- **Slide Viewer**: For text/image based content

## Offline Support

DiabetesBuddy implements a comprehensive offline strategy:

1. **Local Storage**: User data, progress, and completed lessons cached using Hive
2. **Content Caching**: Educational content stored locally for offline access
3. **Synchronization**: Changes made offline synchronized when connection restored

## Testing

### Unit Tests

Tests for core services and business logic can be run with:

```bash
flutter test test/services/
```

### Widget Tests

UI component tests can be run with:

```bash
flutter test test/widgets/
```

## Deployment

### Android

Build an APK with:

```bash
flutter build apk --release
```

### iOS

Build for iOS with:

```bash
flutter build ios --release
```

## Future Enhancements

- Community features and social sharing
- Personalized reminders based on user behavior
- Advanced analytics for healthcare providers
- Multi-language support
- Expanded content library
- Integration with medical devices and health apps

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- [Flutter](https://flutter.dev/) for the incredible cross-platform framework
- [Firebase](https://firebase.google.com/) for backend services
- [YouTube API](https://developers.google.com/youtube/v3) for video integration

## Support

For support or questions, please contact us at support@diabetesbuddy.app
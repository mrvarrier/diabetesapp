# Project Setup Guide

## Directory Structure Setup

Create the following directory structure in your project:

```
diabetes_edu/
├── android/
├── ios/
├── lib/          # All the Dart code provided goes here
├── assets/
│   ├── fonts/
│   ├── images/
│   └── icons/
├── test/
└── pubspec.yaml  # The file provided above
```

## Assets Setup

### Fonts

1. Download the Poppins font family files:
    - [Poppins-Regular.ttf](https://fonts.google.com/specimen/Poppins)
    - [Poppins-Medium.ttf](https://fonts.google.com/specimen/Poppins)
    - [Poppins-SemiBold.ttf](https://fonts.google.com/specimen/Poppins)
    - [Poppins-Bold.ttf](https://fonts.google.com/specimen/Poppins)

2. Place these files in the `assets/fonts/` directory

### Images

For the MVP, you'll need some placeholder images:

1. Create placeholder images for:
    - `assets/images/onboarding_1.png`
    - `assets/images/onboarding_2.png`
    - `assets/images/onboarding_3.png`
    - `assets/images/onboarding_4.png`
    - `assets/images/app_logo.png`

If you don't have these images, you can use any placeholder images or create simple ones using tools like [Canva](https://www.canva.com/).

## Firebase Setup

1. Create a new Firebase project at [firebase.google.com](https://firebase.google.com)

2. Add an Android app to your Firebase project:
    - Package name: `com.example.diabetes_edu` (or your custom package name)
    - Download the `google-services.json` file
    - Place it in the `android/app/` directory

3. Add an iOS app to your Firebase project:
    - Bundle ID: `com.example.diabetesEdu` (or your custom bundle ID)
    - Download the `GoogleService-Info.plist` file
    - Place it in the `ios/Runner/` directory

4. Enable Authentication in Firebase:
    - Go to Authentication > Sign-in method
    - Enable Email/Password authentication

5. Create Firestore Database:
    - Go to Firestore Database
    - Create database (start in test mode for development)

6. Set up initial Firestore collections (as described in the README)

## YouTube API Setup

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project
3. Enable the YouTube Data API v3
4. Create API credentials (API Key)
5. In the file `lib/data/services/youtube_service.dart`, replace:
   ```dart
   final String _apiKey = 'YOUR_YOUTUBE_API_KEY';
   ```
   with your actual API key:
   ```dart
   final String _apiKey = 'AIza...'; // Your actual key
   ```

## Running the App

After completing the setup:

1. Install dependencies:
   ```bash
   flutter pub get
   ```

2. Run the app:
   ```bash
   flutter run
   ```

## Troubleshooting

### Common Setup Issues

1. **Firebase dependency conflicts**
    - If you encounter Firebase dependency conflicts, make sure your Flutter and Firebase versions are compatible
    - Try running: `flutter pub upgrade --major-versions`

2. **YouTube API key issues**
    - Ensure your YouTube API key has the YouTube Data API v3 enabled
    - Check if your API key has any restrictions (like HTTP referrers or IP addresses)

3. **Image asset not found**
    - Verify that all image paths in the code match your actual asset directory structure
    - Run `flutter clean` and then `flutter pub get` to refresh asset registration

4. **Font loading issues**
    - Ensure font filenames match exactly what's specified in pubspec.yaml
    - Check that the font files are correctly placed in the assets/fonts directory
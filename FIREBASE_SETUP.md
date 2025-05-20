# Firebase Integration Guide

This guide will help you set up Firebase for the DiabetesBuddy app, including authentication, Firestore database, storage, and push notifications.

## Prerequisites

- Flutter development environment set up
- A Google account for Firebase access
- Basic understanding of Firebase services

## Step 1: Create a Firebase Project

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter "DiabetesBuddy" as the project name
4. Choose whether to enable Google Analytics (recommended)
5. Select your Analytics account or create a new one
6. Click "Create project"

## Step 2: Register Your Flutter App with Firebase

### For Android:

1. In Firebase Console, select your project
2. Click the Android icon (</>) to add an Android app
3. Enter your app's package name: `com.example.diabetes_buddy` (or your actual package name)
4. Enter a nickname: "DiabetesBuddy Android"
5. Enter SHA-1 signing certificate (optional but recommended for authentication)
6. Click "Register app"
7. Download the `google-services.json` file
8. Place it in the `android/app` directory of your Flutter project
9. Follow the instructions to add the Firebase SDK to your Android app

### For iOS:

1. In Firebase Console, select your project
2. Click the iOS icon (</>) to add an iOS app
3. Enter your app's Bundle ID (found in Xcode project settings)
4. Enter a nickname: "DiabetesBuddy iOS"
5. Enter App Store ID (optional)
6. Click "Register app"
7. Download the `GoogleService-Info.plist` file
8. Place it in the `ios/Runner` directory of your Flutter project
9. Follow the instructions to add the Firebase SDK to your iOS app

## Step 3: Update Flutter Project Configuration

### Android Configuration

1. Modify `android/build.gradle`:

```gradle
buildscript {
    repositories {
        // ...
        google()  // Make sure this is included
    }
    dependencies {
        // ...
        classpath 'com.google.gms:google-services:4.3.15'  // Add this line
    }
}

allprojects {
    repositories {
        // ...
        google()  // Make sure this is included
    }
}
```

2. Modify `android/app/build.gradle`:

```gradle
apply plugin: 'com.android.application'
apply plugin: 'kotlin-android'
apply plugin: 'com.google.gms.google-services'  // Add this line

android {
    // ...
    defaultConfig {
        minSdkVersion 21  // Ensure this is at least 21
        // ...
    }
}

dependencies {
    // ...
    implementation platform('com.google.firebase:firebase-bom:32.0.0')
    implementation 'com.google.firebase:firebase-analytics-ktx'
}
```

### iOS Configuration

1. Open `ios/Podfile` and set the minimum iOS version:

```ruby
platform :ios, '12.0'
```

2. Add the Firebase pods to your `ios/Podfile`:

```ruby
target 'Runner' do
  # ...
  pod 'Firebase/Core'
  pod 'Firebase/Auth'
  pod 'Firebase/Firestore'
  pod 'Firebase/Storage'
  pod 'Firebase/Messaging'
  pod 'Firebase/Analytics'
end
```

3. Run `pod install` from the `ios` directory

## Step 4: Initialize Firebase in Flutter App

Create a file `lib/firebase_options.dart` with your Firebase configuration. If you're using FlutterFire CLI, run:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

If configuring manually, ensure your `main.dart` initializes Firebase:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}
```

## Step 5: Enable Firebase Services

### Authentication

1. In Firebase Console, navigate to "Authentication"
2. Click "Get started"
3. Enable Email/Password sign-in method
4. (Optional) Enable other sign-in methods like Google, Facebook, etc.

### Cloud Firestore

1. Navigate to "Firestore Database"
2. Click "Create database"
3. Start in production mode (or test mode for development)
4. Choose a database location closest to your target users
5. Click "Enable"

### Cloud Storage

1. Navigate to "Storage"
2. Click "Get started"
3. Review and accept the default storage rules
4. Choose a storage location closest to your target users
5. Click "Done"

### Cloud Messaging (for Push Notifications)

1. Navigate to "Messaging"
2. Click "Get started"
3. Set up an Android app by providing your server key (found in Project Settings > Cloud Messaging)
4. For iOS, upload your APNs authentication key (requires an Apple Developer account)

## Step 6: Configure Firebase Security Rules

### Firestore Rules

Navigate to Firestore Database > Rules and update with the rules found in the `DATABASE_STRUCTURE.md` file.

### Storage Rules

Navigate to Storage > Rules and update with:

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

For production, refine these rules to be more restrictive.

## Step 7: Set Up Firebase Indexes

1. Navigate to Firestore Database > Indexes
2. Add the composite indexes specified in the `DATABASE_STRUCTURE.md` file
3. Click "Create index" for each index

## Step 8: Seed Initial Data (Admin Only)

You'll need to create initial data for:

1. Default education plans
2. Modules
3. Content
4. Quizzes
5. Achievements

You can use Firebase Console to manually add this data, or create a seeding script using the Firebase Admin SDK.

## Step 9: Test Your Firebase Integration

Add a simple test in your Flutter app to verify Firebase is properly configured:

```dart
Future<void> testFirebase() async {
  try {
    // Test Firestore
    await FirebaseFirestore.instance.collection('test').add({
      'message': 'Hello Firebase',
      'timestamp': FieldValue.serverTimestamp(),
    });
    print('Firebase Firestore is working!');
    
    // Test Authentication (anonymous)
    UserCredential userCredential = await FirebaseAuth.instance.signInAnonymously();
    print('Firebase Auth is working. User ID: ${userCredential.user?.uid}');
    
  } catch (e) {
    print('Firebase test failed: $e');
  }
}
```

## Step 10: Set Up Firebase Analytics

To track user behavior and app usage:

1. Ensure `firebase_analytics` package is properly configured
2. Add tracking for key events:

```dart
final analytics = FirebaseAnalytics.instance;

// Log a login event
await analytics.logLogin(loginMethod: 'email');

// Log screen view
await analytics.logScreenView(
  screenName: 'home_screen',
  screenClass: 'HomePage',
);

// Log custom event
await analytics.logEvent(
  name: 'lesson_completed',
  parameters: {
    'lesson_id': 'abc123',
    'lesson_name': 'Introduction to Diabetes',
  },
);
```

## Troubleshooting

### Common Issues:

1. **Gradle build failures on Android**:
    - Ensure your `google-services.json` is in the correct location
    - Update Gradle and Kotlin versions if needed
    - Check for compatibility between Firebase SDK and Flutter version

2. **iOS build failures**:
    - Ensure your `GoogleService-Info.plist` is in the correct location
    - Run `pod update` in the iOS directory
    - Check minimum iOS platform version compatibility

3. **Runtime Firebase errors**:
    - Verify Firebase initialization is complete before making Firebase calls
    - Check internet connectivity
    - Verify Firebase project settings and API keys

4. **Push notification issues**:
    - For Android, check if the app is in battery optimization whitelist
    - For iOS, verify Push Notification entitlement is enabled
    - Check FCM token registration process

### Firebase Console Debugging:

1. Use the "Debug" section in Firebase Console to check:
    - Authentication: User sign-ins, account creation
    - Firestore: Document reads/writes
    - Functions: Execution logs
    - Analytics: Event logging

## Next Steps

Once your Firebase setup is complete:

1. Implement your authentication flows in the app
2. Set up Firestore data access with proper error handling
3. Configure push notifications for engagement
4. Use Firebase Analytics to track user behavior
5. Consider adding Firebase Crashlytics for crash reporting

## Resources

- [FlutterFire Documentation](https://firebase.flutter.dev/docs/overview/)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Flutter Firebase Codelab](https://firebase.google.com/codelabs/firebase-get-to-know-flutter)
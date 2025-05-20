# Testing Strategy for DiabetesBuddy

This document outlines the testing approach for the DiabetesBuddy Flutter application, covering unit tests, widget tests, integration tests, and manual testing procedures.

## Testing Goals

1. Ensure core functionality works across different devices and platforms
2. Verify that offline functionality properly syncs when connectivity is restored
3. Validate that the educational content and quizzes function correctly
4. Confirm that gamification elements (points, streaks, achievements) work as expected
5. Test security of user data and authentication

## Testing Levels

### 1. Unit Tests

Unit tests focus on testing individual components in isolation. They are fast, reliable, and help catch bugs early.

#### Test Targets:

- **Service classes**:
    - `AuthService`: Test login, registration, password reset
    - `DatabaseService`: Test data operations
    - `ContentService`: Test content retrieval and caching
    - `PointsService`: Test point allocation and streak counting
    - `YouTubeService`: Test video playback tracking
    - `LocalStorageService`: Test offline data storage

- **Model classes**:
    - Test data conversion to and from JSON
    - Test validation methods
    - Test business logic in model methods

#### Sample Unit Test (AuthService):

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:diabetes_buddy/services/auth_service.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUserCredential extends Mock implements UserCredential {}
class MockUser extends Mock implements User {}

void main() {
  late AuthService authService;
  late MockFirebaseAuth mockFirebaseAuth;
  
  setUp(() {
    mockFirebaseAuth = MockFirebaseAuth();
    authService = AuthService(firebaseAuth: mockFirebaseAuth);
  });
  
  group('signInWithEmailAndPassword', () {
    test('should return UserCredential when Firebase Auth succeeds', () async {
      // Arrange
      final mockUserCredential = MockUserCredential();
      when(mockFirebaseAuth.signInWithEmailAndPassword(
        email: 'test@example.com',
        password: 'password123',
      )).thenAnswer((_) async => mockUserCredential);
      
      // Act
      final result = await authService.signInWithEmailAndPassword(
        'test@example.com',
        'password123',
      );
      
      // Assert
      expect(result, equals(mockUserCredential));
    });
    
    test('should throw exception when Firebase Auth fails', () async {
      // Arrange
      when(mockFirebaseAuth.signInWithEmailAndPassword(
        email: 'test@example.com',
        password: 'password123',
      )).thenThrow(FirebaseAuthException(code: 'user-not-found'));
      
      // Act & Assert
      expect(
        () => authService.signInWithEmailAndPassword(
          'test@example.com',
          'password123',
        ),
        throwsA(isA<FirebaseAuthException>()),
      );
    });
  });
  
  // Additional test groups for other methods...
}
```

### 2. Widget Tests

Widget tests verify that UI components render correctly and handle user interactions appropriately.

#### Test Targets:

- **Authentication screens**:
    - Test form validation
    - Test loading states
    - Test error messages

- **Content viewers**:
    - Test video player controls
    - Test slide navigation
    - Test quiz interaction

- **Shared widgets**:
    - Test custom buttons
    - Test custom input fields
    - Test lesson cards

#### Sample Widget Test (LoginPage):

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:diabetes_buddy/screens/authentication/login_page.dart';
import 'package:diabetes_buddy/services/auth_service.dart';

class MockAuthService extends Mock implements AuthService {}

void main() {
  late MockAuthService mockAuthService;
  
  setUp(() {
    mockAuthService = MockAuthService();
  });
  
  testWidgets('should show error message on login failure', (WidgetTester tester) async {
    // Arrange
    when(mockAuthService.signInWithEmailAndPassword(
      'test@example.com',
      'password123',
    )).thenThrow(Exception('Invalid credentials'));
    
    // Build the widget
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<AuthService>.value(
          value: mockAuthService,
          child: const LoginPage(),
        ),
      ),
    );
    
    // Enter email and password
    await tester.enterText(find.byType(TextFormField).at(0), 'test@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    
    // Tap login button
    await tester.tap(find.text('Sign In'));
    await tester.pump();
    
    // Verify error message is displayed
    expect(find.text('An unexpected error occurred. Please try again.'), findsOneWidget);
  });
  
  // Additional test cases...
}
```

### 3. Integration Tests

Integration tests verify that different parts of the app work together correctly.

#### Test Targets:

- **User flows**:
    - Registration → Onboarding → Home
    - Login → Watch Video → Take Quiz → Earn Points
    - Complete Lesson → Unlock Achievement

- **Synchronization**:
    - Go offline → Make changes → Go online → Verify sync

#### Sample Integration Test:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:diabetes_buddy/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('end-to-end tests', () {
    testWidgets('complete lesson flow', (tester) async {
      // Start app
      app.main();
      await tester.pumpAndSettle();
      
      // Login (assuming we start at login screen)
      await tester.enterText(find.byKey(const Key('email_field')), 'test@example.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'password123');
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();
      
      // Navigate to education plan
      await tester.tap(find.byKey(const Key('education_plan_button')));
      await tester.pumpAndSettle();
      
      // Select first lesson
      await tester.tap(find.byKey(const Key('lesson_item_0')));
      await tester.pumpAndSettle();
      
      // Watch video (simulate)
      await tester.tap(find.byKey(const Key('play_button')));
      await Future.delayed(const Duration(seconds: 5)); // Simulate watching
      await tester.pumpAndSettle();
      
      // Complete quiz
      await tester.tap(find.byKey(const Key('take_quiz_button')));
      await tester.pumpAndSettle();
      
      // Select answers for all questions
      await tester.tap(find.byKey(const Key('option_0')));
      await tester.tap(find.byKey(const Key('submit_button')));
      await tester.pumpAndSettle();
      
      // Go to next question
      await tester.tap(find.byKey(const Key('next_button')));
      await tester.pumpAndSettle();
      
      // Verify completion
      expect(find.text('Quiz Complete!'), findsOneWidget);
      expect(find.text('Points Earned'), findsOneWidget);
    });
  });
}
```

### 4. Manual Testing

Some aspects require manual testing, especially those involving third-party services or complex user interactions.

#### Test Targets:

- **YouTube video integration**:
    - Test video playback in different network conditions
    - Test videos with different durations and resolutions

- **Offline functionality**:
    - Test app behavior when switching between online and offline
    - Test synchronization edge cases

- **Push notifications**:
    - Test notification delivery and interaction

- **Cross-platform behavior**:
    - Test on different Android and iOS versions
    - Test on tablets and phones

#### Manual Test Checklist:

```
□ App installs correctly on Android and iOS
□ User can register and verify email
□ User can login with email and password
□ User can complete onboarding
□ Home screen shows correct user information
□ Videos play correctly and track progress
□ Slides display correctly and navigation works
□ Quizzes function correctly with feedback
□ Points are awarded appropriately
□ Streaks increment correctly on daily use
□ Achievements unlock based on criteria
□ Push notifications arrive and action correctly
□ App functions in offline mode
□ Changes made offline sync when connection restored
□ Progress reports generate and display correctly
□ Settings changes are persisted
□ User can log out and log back in
□ Dark mode works correctly throughout app
```

## Test Environment Setup

### Tools Required:

1. **Flutter Test**: Built-in testing framework
2. **Mockito**: Mocking framework for unit tests
3. **Integration_test**: Package for integration testing
4. **Firebase Emulator Suite**: For testing Firebase services locally

### Emulator Setup:

```bash
# Install Firebase tools
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize emulator
firebase init emulators

# Start emulators
firebase emulators:start
```

### Test Configuration:

Create a `test_config.dart` file with test environment settings:

```dart
class TestConfig {
  static const bool useEmulator = true;
  static const String emulatorHost = 'localhost';
  static const int authPort = 9099;
  static const int firestorePort = 8080;
  
  // Test accounts
  static const String testEmail = 'test@example.com';
  static const String testPassword = 'Test123!';
  
  // Test content IDs
  static const String testVideoContentId = 'test_video_1';
  static const String testSlideContentId = 'test_slide_1';
  static const String testQuizId = 'test_quiz_1';
}
```

## Continuous Integration

### GitHub Actions Workflow:

```yaml
name: Flutter CI

on:
  push:
    branches: [ main, dev ]
  pull_request:
    branches: [ main, dev ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.10.0'
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Analyze project
        run: flutter analyze
      
      - name: Run unit tests
        run: flutter test
      
      # For integration tests, you'll need to set up emulators or use a service like Firebase Test Lab
```

## Test Data Generation

Create mock data for testing:

### Sample Test Data Script:

```dart
class TestDataGenerator {
  static Future<void> seedTestData(FirebaseFirestore firestore) async {
    // Create test user
    await firestore.collection('users').doc('test_user_id').set({
      'email': 'test@example.com',
      'fullName': 'Test User',
      'age': 35,
      'gender': 'Other',
      'diabetesType': 'Type 2',
      'treatmentMethod': 'Oral Medication',
      'points': 0,
      'streakDays': 0,
      'lastActive': FieldValue.serverTimestamp(),
      'onboardingComplete': true,
      'completedLessons': [],
      'unlockedAchievements': [],
      'assignedPlanId': 'test_plan_id',
      'notificationSettings': {
        'dailyReminder': true,
        'achievements': true,
        'newContent': true,
      },
      'isDarkModeEnabled': false,
    });
    
    // Create test education plan
    await firestore.collection('education_plans').doc('test_plan_id').set({
      'title': 'Test Education Plan',
      'description': 'Plan for testing',
      'diabetesType': 'Type 2',
      'isDefault': true,
      'isActive': true,
      'moduleIds': ['test_module_id'],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    // Add additional test data for modules
    await firestore.collection('modules').doc('test_module_id').set({
      'title': 'Test Module',
      'description': 'Module for testing',
      'planId': 'test_plan_id',
      'sequenceNumber': 1,
      'estimatedDuration': 60,
      'iconName': 'book',
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    // Add test content (video)
    await firestore.collection('content').doc('test_video_1').set({
      'title': 'Introduction to Diabetes',
      'description': 'Learn the basics of diabetes management',
      'contentType': 'video',
      'youtubeVideoId': 'dQw4w9WgXcQ', // Use a real video ID for testing
      'slideUrls': [],
      'slideContents': [],
      'pointsValue': 10,
      'moduleId': 'test_module_id',
      'sequenceNumber': 1,
      'estimatedDuration': 15,
      'isActive': true,
      'isDownloadable': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'metadata': {},
    });
    
    // Add test content (slides)
    await firestore.collection('content').doc('test_slide_1').set({
      'title': 'Diabetes Medication Overview',
      'description': 'Learn about different medications for diabetes',
      'contentType': 'slides',
      'youtubeVideoId': '',
      'slideUrls': [],
      'slideContents': [
        'Slide 1: Introduction to Diabetes Medications',
        'Slide 2: Oral Medications',
        'Slide 3: Injectable Medications',
        'Slide 4: Side Effects',
        'Slide 5: Summary',
      ],
      'pointsValue': 10,
      'moduleId': 'test_module_id',
      'sequenceNumber': 2,
      'estimatedDuration': 10,
      'isActive': true,
      'isDownloadable': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'metadata': {},
    });
    
    // Add test quiz
    await firestore.collection('quizzes').doc('test_quiz_1').set({
      'title': 'Diabetes Basics Quiz',
      'description': 'Test your knowledge of diabetes basics',
      'moduleId': 'test_module_id',
      'contentId': 'test_video_1',
      'pointsValue': 15,
      'passingScore': 70,
      'questions': [
        {
          'questionText': 'What hormone is lacking in Type 1 diabetes?',
          'options': ['Insulin', 'Glucagon', 'Cortisol', 'Thyroxine'],
          'correctOptionIndex': 0,
          'explanation': 'In Type 1 diabetes, the pancreas produces little or no insulin.',
        },
        {
          'questionText': 'Which of these is NOT a symptom of high blood sugar?',
          'options': ['Increased thirst', 'Frequent urination', 'Weight gain', 'Blurred vision'],
          'correctOptionIndex': 2,
          'explanation': 'Weight loss, not weight gain, is a common symptom of high blood sugar.',
        },
      ],
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    // Add test achievements
    await firestore.collection('achievements').doc('test_achievement_1').set({
      'title': 'First Lesson',
      'description': 'Complete your first lesson',
      'iconPath': 'assets/icons/first_lesson.png',
      'pointsValue': 20,
      'achievementType': 'completion',
      'criteria': {
        'lessonsCompleted': 1,
      },
      'isHidden': false,
    });
    
    await firestore.collection('achievements').doc('test_achievement_2').set({
      'title': 'Getting Streaky',
      'description': 'Maintain a 3-day learning streak',
      'iconPath': 'assets/icons/streak.png',
      'pointsValue': 30,
      'achievementType': 'streak',
      'criteria': {
        'days': 3,
      },
      'isHidden': false,
    });
  }
}
```

## Performance Testing

Performance testing ensures the app runs smoothly under various conditions.

### Key Metrics to Test:

1. **App startup time**: Measure time from launch to interactive UI
2. **Video loading time**: Measure time to load and start playback
3. **Memory usage**: Monitor memory consumption during extended use
4. **Battery usage**: Measure battery drain during video playback
5. **Network efficiency**: Measure data usage for different content types

### Sample Performance Test (Startup Time):

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:diabetes_buddy/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  testWidgets('measure app startup time', (WidgetTester tester) async {
    final Stopwatch stopwatch = Stopwatch()..start();
    
    // Start the app
    app.main();
    
    // Wait for the login page to appear
    await tester.pumpAndSettle();
    
    // Stop the timer
    stopwatch.stop();
    
    // Log the result
    print('App startup time: ${stopwatch.elapsedMilliseconds}ms');
    
    // Optional: Assert that startup time is within acceptable limits
    expect(stopwatch.elapsedMilliseconds, lessThan(3000)); // < 3 seconds
  });
}
```

## Accessibility Testing

Ensure the app is accessible to users with different abilities.

### Areas to Test:

1. **Screen reader compatibility**: Test with TalkBack (Android) and VoiceOver (iOS)
2. **Text scaling**: Test with different font sizes
3. **Color contrast**: Ensure text is readable on all backgrounds
4. **Keyboard/switch navigation**: Test that all features can be accessed without touch

### Accessibility Checklist:

```
□ All images have meaningful alternative text
□ Text contrast ratios meet WCAG AA standards (4.5:1 for normal text)
□ Interactive elements have appropriate hit target sizes (at least 48x48dp)
□ All functionality is accessible via screen readers
□ App is usable at 200% text size
□ Focus order is logical and follows visual layout
□ Error messages are announced by screen readers
□ Videos have captions or transcripts available
□ No content relies solely on color to convey meaning
□ Animations can be disabled for users with vestibular disorders
```

## Security Testing

Verify that user data is protected and authentication is secure.

### Security Test Areas:

1. **Data encryption**: Verify sensitive data is encrypted at rest
2. **Authentication security**: Test for vulnerabilities in login flow
3. **Input validation**: Test for injection attacks in user inputs
4. **Secure storage**: Verify credentials are stored securely
5. **Network security**: Verify all API calls use HTTPS

### Security Testing Tools:

- **MobSF**: Mobile Security Framework for static and dynamic analysis
- **OWASP ZAP**: Web security scanner for API testing
- **Burp Suite**: For intercepting and analyzing network traffic

## Testing Documentation

Create comprehensive test documentation to ensure consistency.

### Test Case Template:

```
Test ID: TC-001
Title: User Login with Valid Credentials
Priority: High
Description: Verify that a user can successfully login with valid credentials
Preconditions: 
  - User has a registered account
  - User is on the login screen
Test Steps:
  1. Enter valid email
  2. Enter valid password
  3. Tap Login button
Expected Results:
  - User is authenticated
  - User is navigated to the home screen
  - Home screen displays user's name and streak info
Status: Pass/Fail
```

## Testing Schedule

Establish a testing schedule for the development lifecycle:

1. **Daily**: Run unit tests on code changes
2. **Weekly**: Run widget tests and focused integration tests
3. **Bi-weekly**: Run full regression test suite
4. **Pre-release**: Comprehensive manual testing and performance testing

## Bug Reporting Process

Establish a standardized bug reporting process:

1. **Identify**: Discover an issue during testing
2. **Reproduce**: Document exact steps to reproduce
3. **Document**: Record details (environment, severity, screenshots)
4. **Log**: Create issue in bug tracking system
5. **Prioritize**: Assign severity and priority
6. **Track**: Monitor fix status and retest

### Bug Report Template:

```
Bug ID: BUG-001
Title: App crashes when trying to play video offline
Severity: Critical
Priority: High
Environment: 
  - Device: Samsung Galaxy S21
  - OS: Android 12
  - App Version: 1.0.0
Reproducibility: 100% (5/5 attempts)
Steps to Reproduce:
  1. Login to the app
  2. Enable airplane mode
  3. Navigate to Education Plan
  4. Select any video lesson
  5. Tap Play button
Actual Result: App crashes with "Null reference exception"
Expected Result: App should display an offline message
Screenshots/Logs: [Attached]
```

## References

- [Flutter Testing Documentation](https://docs.flutter.dev/testing)
- [Firebase Test Lab](https://firebase.google.com/docs/test-lab)
- [WCAG 2.1 AA Standards](https://www.w3.org/TR/WCAG21/)
- [OWASP Mobile Security Testing Guide](https://owasp.org/www-project-mobile-security-testing-guide/)
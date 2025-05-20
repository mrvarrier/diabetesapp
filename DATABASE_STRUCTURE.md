# Firestore Database Structure

## Overview

The DiabetesBuddy app uses Firebase Firestore as its primary database. This document outlines the database collections, document structures, and relationships.

## Collections

### 1. users

Stores user profiles and preferences.

```
users/{uid}
├── email: string
├── fullName: string
├── age: number
├── gender: string
├── diabetesType: string
├── treatmentMethod: string
├── points: number
├── streakDays: number
├── lastActive: timestamp
├── onboardingComplete: boolean
├── completedLessons: array<string> // Content IDs
├── unlockedAchievements: array<string> // Achievement IDs
├── assignedPlanId: string
├── notificationSettings: map
│   ├── dailyReminder: boolean
│   ├── achievements: boolean
│   └── newContent: boolean
└── isDarkModeEnabled: boolean
```

### 2. education_plans

Defines educational plans for different diabetes types.

```
education_plans/{planId}
├── title: string
├── description: string
├── diabetesType: string
├── isDefault: boolean
├── isActive: boolean
├── moduleIds: array<string>
├── createdAt: timestamp
└── updatedAt: timestamp
```

### 3. modules

Groups related lessons into coherent modules.

```
modules/{moduleId}
├── title: string
├── description: string
├── planId: string
├── sequenceNumber: number
├── estimatedDuration: number // in minutes
├── iconName: string
├── isActive: boolean
├── createdAt: timestamp
└── updatedAt: timestamp
```

### 4. content

Educational materials (videos, slides, etc.).

```
content/{contentId}
├── title: string
├── description: string
├── contentType: string // "video", "slides", or "mixed"
├── youtubeVideoId: string
├── slideUrls: array<string>
├── slideContents: array<string>
├── pointsValue: number
├── moduleId: string
├── sequenceNumber: number
├── estimatedDuration: number // in minutes
├── isActive: boolean
├── isDownloadable: boolean
├── createdAt: timestamp
├── updatedAt: timestamp
└── metadata: map
```

### 5. quizzes

Knowledge assessments for content.

```
quizzes/{quizId}
├── title: string
├── description: string
├── moduleId: string
├── contentId: string
├── pointsValue: number
├── passingScore: number // percentage needed to pass
├── questions: array<map>
│   ├── questionText: string
│   ├── options: array<string>
│   ├── correctOptionIndex: number
│   └── explanation: string
├── isActive: boolean
├── createdAt: timestamp
└── updatedAt: timestamp
```

### 6. progress

Tracks user progress through content.

```
progress/{progressId}
├── userId: string
├── contentId: string
├── isCompleted: boolean
├── pointsEarned: number
├── startTime: timestamp
├── completionTime: timestamp (optional)
├── watchTimeSeconds: number
└── metadata: map
    ├── quizAttempted: boolean
    ├── quizPassed: boolean
    ├── quizScore: number
    └── deviceInfo: map
```

### 7. achievements

Defines achievements users can unlock.

```
achievements/{achievementId}
├── title: string
├── description: string
├── iconPath: string
├── pointsValue: number
├── achievementType: string // "streak", "completion", "quiz", etc.
├── criteria: map
│   ├── days: number (for streak type)
│   ├── lessonsCompleted: number (for completion type)
│   ├── points: number (for points type)
│   └── contentId: string (for specific content)
└── isHidden: boolean
```

### 8. notifications

Stores notification content and delivery status.

```
notifications/{notificationId}
├── userId: string
├── title: string
├── body: string
├── notificationType: string
├── data: map
├── createdAt: timestamp
├── isRead: boolean
└── actionRoute: string
```

### 9. feedback

User ratings and comments on content.

```
feedback/{feedbackId}
├── userId: string
├── contentId: string
├── rating: number // 1-5
├── comment: string (optional)
├── createdAt: timestamp
└── metadata: map
```

### 10. analytics

Usage statistics and events.

```
analytics/{eventId}
├── userId: string
├── event: string
├── timestamp: timestamp
├── platform: string
└── parameters: map
```

### 11. admins

Admin user permissions.

```
admins/{uid}
├── email: string
├── role: string
├── permissions: array<string>
└── lastAccess: timestamp
```

## Relationships

- Each **user** has one assigned **education_plan**
- Each **education_plan** contains multiple **modules**
- Each **module** contains multiple **content** items
- Each **content** item may have one **quiz**
- Each **user** has multiple **progress** entries (one per content)
- Each **user** can unlock multiple **achievements**
- Each **user** receives multiple **notifications**
- Each **user** can provide **feedback** on multiple content items

## Indexes

For optimal query performance, the following indexes should be created:

1. **progress** collection:
    - Compound index on `userId` (ascending) and `contentId` (ascending)
    - Compound index on `userId` (ascending) and `isCompleted` (ascending)

2. **content** collection:
    - Compound index on `moduleId` (ascending) and `sequenceNumber` (ascending)
    - Compound index on `moduleId` (ascending) and `isActive` (ascending)

3. **notifications** collection:
    - Compound index on `userId` (ascending) and `isRead` (ascending) and `createdAt` (descending)

4. **analytics** collection:
    - Compound index on `userId` (ascending) and `event` (ascending) and `timestamp` (descending)

## Security Rules

Firestore security rules should enforce:

1. User data is only accessible to the user themselves and admins
2. Content, modules, and education plans are readable by any authenticated user
3. Progress, feedback, and notifications are only readable/writable by the respective user
4. Admin collections are only accessible to users with admin permissions

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Check if user is authenticated
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // Check if user is accessing their own data
    function isUser(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    // Check if user is an admin
    function isAdmin() {
      return isAuthenticated() && exists(/databases/$(database)/documents/admins/$(request.auth.uid));
    }
    
    // User profiles
    match /users/{userId} {
      allow read: if isUser(userId) || isAdmin();
      allow write: if isUser(userId) || isAdmin();
    }
    
    // Education plans
    match /education_plans/{planId} {
      allow read: if isAuthenticated();
      allow write: if isAdmin();
    }
    
    // Modules
    match /modules/{moduleId} {
      allow read: if isAuthenticated();
      allow write: if isAdmin();
    }
    
    // Content
    match /content/{contentId} {
      allow read: if isAuthenticated();
      allow write: if isAdmin();
    }
    
    // Quizzes
    match /quizzes/{quizId} {
      allow read: if isAuthenticated();
      allow write: if isAdmin();
    }
    
    // Progress tracking
    match /progress/{progressId} {
      allow read: if isAuthenticated() && (resource.data.userId == request.auth.uid || isAdmin());
      allow create, update: if isAuthenticated() && request.resource.data.userId == request.auth.uid;
      allow delete: if isAdmin();
    }
    
    // Achievements
    match /achievements/{achievementId} {
      allow read: if isAuthenticated();
      allow write: if isAdmin();
    }
    
    // Notifications
    match /notifications/{notificationId} {
      allow read: if isAuthenticated() && resource.data.userId == request.auth.uid;
      allow write: if isAdmin();
      allow update: if isAuthenticated() && resource.data.userId == request.auth.uid && request.resource.data.diff(resource.data).affectedKeys().hasOnly(['isRead']);
    }
    
    // Feedback
    match /feedback/{feedbackId} {
      allow read: if isAuthenticated() && (resource.data.userId == request.auth.uid || isAdmin());
      allow create: if isAuthenticated() && request.resource.data.userId == request.auth.uid;
      allow update, delete: if isAdmin();
    }
    
    // Analytics
    match /analytics/{eventId} {
      allow read: if isAdmin();
      allow create: if isAuthenticated();
      allow update, delete: if false;
    }
    
    // Admins
    match /admins/{userId} {
      allow read: if isUser(userId);
      allow write: if isAdmin();
    }
  }
}
```
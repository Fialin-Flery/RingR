# Ringr

Ringr is a Flutter-based calling application that allows users to connect with other registered Ringr users through audio and video calls.

The project uses Firebase for authentication and user data management and ZEGOCLOUD for real-time audio/video calling.

---

## Features

### Authentication

- Google Sign-In using Firebase Authentication
- Persistent login session
- Automatic routing for logged-in users
- Registration flow for first-time users

### User Registration

Users can create their Ringr profile with:

- Name
- Email
- Phone number
- Camera permission
- Microphone permission
- Contacts permission

### Home

The home screen provides:

- User profile information
- Recent calls
- Contacts
- Calling shortcuts
- Call status information

### Contacts

Ringr supports:

- Device contacts
- Registered Ringr users
- Contact search
- Name/phone/email based search
- Ringr verification status
- Online/offline status
- Audio call button
- Video call button
- Invite option for users who are not registered

### Calling

Ringr uses ZEGOCLOUD for real-time communication.

Supported:

- One-to-one audio calls
- One-to-one video calls
- Group audio calls
- Group video calls

Call states include:

- Calling
- Ringing
- Connected
- In Call
- Ended
- Rejected
- Missed
- Busy
- Failed
- Disconnected

### Video Call Preview

Before starting a video call, users can preview their camera and then choose to start the video call.

### Call History

Ringr maintains call history containing information such as:

- Caller/callee
- Call type
- Call status
- Time
- Duration

### Profile

Users can:

- View their profile
- Edit their profile
- Update personal information
- Log out

---

## Tech Stack

| Technology | Purpose |
|---|---|
| Flutter | Cross-platform application development |
| Dart | Application programming language |
| Firebase Authentication | Google authentication |
| Cloud Firestore | User/profile data |
| ZEGOCLOUD | Audio/video calling |
| Android Studio | Development environment |
| Git & GitHub | Version control |

---

## Project Structure

```text
RingR/
│
├── assets/
│   └── images/
│       ├── ringr_logo.png
│       ├── ringr_logo_cropped.png
│       ├── ringr_icon.png
│       └── google.png
│
├── lib/
│   │
│   ├── models/
│   │   ├── call_model.dart
│   │   └── contact_model.dart
│   │
│   ├── screens/
│   │   ├── auth/
│   │   │   └── login_page.dart
│   │   │
│   │   ├── calls/
│   │   │   ├── calls_page.dart
│   │   │   ├── group_call_page.dart
│   │   │   ├── group_video_preview_page.dart
│   │   │   └── video_call_preview_page.dart
│   │   │
│   │   ├── contacts/
│   │   │   ├── contact_tile.dart
│   │   │   └── contacts_page.dart
│   │   │
│   │   ├── home/
│   │   │   └── home_page.dart
│   │   │
│   │   ├── launch/
│   │   │   └── launch_page.dart
│   │   │
│   │   ├── profile/
│   │   │   └── profile_page.dart
│   │   │
│   │   └── registration/
│   │       └── registration_page.dart
│   │
│   ├── services/
│   │   ├── auth_service.dart
│   │   ├── call_service.dart
│   │   ├── contact_service.dart
│   │   ├── user_service.dart
│   │   └── zego_call_service.dart
│   │
│   ├── firebase_options.dart
│   └── main.dart
│
├── android/
│   └── app/
│       └── google-services.json
│
├── pubspec.yaml
└── README.md
```

---

## Firebase Structure

Ringr uses Cloud Firestore to store user information.

### Users

```text
users/{uid}
```

Example fields:

```text
firebaseUserUid
name
email
emailNormalized
phone
phoneNormalized
permissions
isOnline
lastSeen
createdAt
```

### User Directory

```text
userDirectory/{uid}
```

Example fields:

```text
uid
name
phoneLookupKey
emailLookupKey
isOnline
lastSeen
```

The directory is used to help discover registered Ringr users.

---

## Calling Architecture

The basic calling flow is:

```text
Ringr User A
     │
     │ Call invitation
     ▼
Firebase / ZEGOCLOUD
     │
     ▼
Ringr User B
     │
     │ Accept
     ▼
ZEGOCLOUD
     │
     ▼
Audio / Video Call
```

Ringr uses ZEGOCLOUD's calling infrastructure for real-time communication.

The phones do not need to be connected to the same Wi-Fi network.

An internet connection is required.

---

## Getting Started

### Requirements

Install:

- Flutter SDK
- Dart SDK
- Android Studio
- Android SDK
- Git

A physical Android device can be used for testing.

---

## Installation

Clone the repository:

```bash
git clone <YOUR_GITHUB_REPOSITORY_URL>
```

Enter the project:

```bash
cd RingR
```

Install Flutter dependencies:

```bash
flutter pub get
```

Connect an Android device and verify it:

```bash
flutter devices
```

Run the application:

```bash
flutter run
```

---

## Firebase Configuration

The project requires a Firebase project configured for:

- Firebase Authentication
- Google Sign-In
- Cloud Firestore

The Android application must be registered with the correct package name.

Do not commit private Firebase service-account credentials to GitHub.

---

## ZEGOCLOUD Configuration

Ringr uses ZEGOCLOUD for real-time audio/video calling.

The application requires the appropriate ZEGOCLOUD project configuration.

Do not expose production AppSign or other private credentials in a public repository.

---

## Building the APK

To create a release APK:

```bash
flutter build apk --release
```

The generated APK will normally be located at:

```text
build/app/outputs/flutter-apk/app-release.apk
```

---

## Testing

For two-device calling tests:

```text
Phone 1
   │
   │ Internet
   ▼
Firebase / ZEGOCLOUD
   ▲
   │ Internet
   │
Phone 2
```

Both devices should:

1. Have the Ringr app installed.
2. Have an internet connection.
3. Be registered with Ringr.
4. Have the required microphone/camera permissions.
5. Be signed in with different Ringr accounts.

---

## Current Status

The current development build includes:

- Google authentication
- User registration
- Firebase user profiles
- Contacts
- Profile management
- Call history
- ZEGOCLOUD calling
- Audio calling
- Video calling
- Group calling UI
- Call status handling
- Video preview
- Online/offline user status

---

## Future Improvements

Possible future additions include:

- Improved push notification handling
- Background calling improvements
- Full-screen incoming call experience
- Better call history filtering
- Contact synchronization improvements
- Block/report users
- Call recording controls
- End-to-end security improvements
- Better group-call management
- Production backend architecture
- App Store / Play Store deployment

---

## Author

**Fialin Flery Mon**

B.Tech CSE Student  
MNNIT Allahabad

---

## License

This project is currently intended for development and educational purposes.

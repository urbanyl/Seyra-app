<div align="center">

<img src="assets/images/splash_logo.png" alt="Seyra Logo" width="100" />

**Secure, real-time messaging with end-to-end audio/video calls.**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-DD2C00?logo=firebase)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Windows-blue)]()

Seyra is a cross-platform secure messenger built with Flutter and Firebase. It supports real-time text messaging, audio/video calls (1-to-1 and group), group chats, and a clean, modern UI.

</div>

---

## Features

- **Username-based auth** -- Sign up with just a `@username` and password. No email or phone number required.
- **Real-time messaging** -- Instant text, image, file, and GIF messaging powered by Cloud Firestore.
- **Audio & Video calls** -- 1-to-1 and group calls using WebRTC with full mesh topology.
- **Group chats** -- Create groups, add/remove members, manage group identity.
- **Call history** -- Incoming, outgoing, and missed call logs.
- **Contact sync** -- Automatically matches your device contacts with registered users.
- **Profile customization** -- Display name, profile picture, anonymous mode.
- **App lock** -- Passcode + biometric (fingerprint/face) lock screen.
- **Panic code** -- Enter `0000` to instantly wipe all local data and sign out.
- **Dark mode** -- Full dark/light theme with accent color picker.
- **Multi-language** -- French and English localization.
- **Cross-platform** -- Runs on Android, iOS, Web (PWA), and Windows.

## Tech Stack

| Layer | Technology |
|-------|-----------|
| **Framework** | Flutter (Dart) |
| **Backend** | Firebase (Firestore, Auth, Storage) |
| **Real-time** | Cloud Firestore real-time listeners |
| **Calls** | WebRTC (`flutter_webrtc`) |
| **State Management** | Provider |
| **Local Storage** | Hive, SharedPreferences, Flutter Secure Storage |
| **Notifications** | flutter_local_notifications |
| **Contacts** | flutter_contacts |

## Project Structure

```
lib/
  main.dart                          # App entry point + auth routing
  firebase_options.dart              # Firebase config (auto-generated)
  l10n/
    app_localizations.dart           # FR/EN localization
  Models/
    user.dart                        # MyUser model + UserManager (ChangeNotifier)
    chat.dart                        # Chat model
    app_settings.dart                # Settings: lock, notifications, language
    theme.dart                       # Theme engine (dark/light, accent color)
    my_color.dart                    # Custom MaterialColor helper
  Services/
    notification_service.dart        # Local notifications wrapper
  Views/
    Screens/
      auth_screen.dart               # Login / Register (@username + password)
      home_screen.dart               # Main tabbed home (All / Private / Groups / Calls)
      chat_screen.dart               # Individual chat conversation
      call_screen.dart               # WebRTC audio/video call (1-to-1 + group)
      contacts_screen.dart           # Phone contacts list
      create_group.dart              # Create group chat
      group_members_screen.dart      # Manage group members
      account_settings_screen.dart   # Profile, anonymous mode, sign out
      app_settings_screen.dart       # Lock, notifications, language, theme
      lock_screen.dart               # Passcode + biometric lock
      security_info_screen.dart      # Security information page
    Widgets/
      chat_bubble.dart               # Message bubble (text, image, file, GIF)
      chat_input_widget.dart         # Message input + attachment bottom sheet
      chats_list_widget.dart         # Chat list with search, pagination
      chat_list_item.dart            # Individual chat row in list
      contact_list.dart              # Phone contacts with Firebase user matching
      contact_list_item.dart         # Individual contact row
      calls_list_widget.dart         # Call history list
      my_drawer_widget.dart          # Navigation drawer
      neon_avatar.dart               # Custom geometric avatar widget
```

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.x or later)
- A [Firebase project](https://console.firebase.google.com)
- Android Studio / VS Code

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/urbanyl/Seyra-app.git
   cd Seyra-app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**

   The easiest way is with the FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   firebase login
   flutterfire configure --project=your-firebase-project-id
   ```

   This will auto-generate `lib/firebase_options.dart` and `android/app/google-services.json`.

   > If you already have a `google-services.json` from the Firebase Console, place it at `android/app/google-services.json`.

4. **Enable Firebase Services**

   In the [Firebase Console](https://console.firebase.google.com):
   - Go to **Authentication** > **Sign-in method** > Enable **Email/Password**
   - Go to **Firestore Database** > Create database (start in test mode)
   - Set Firestore rules for development:
     ```
     rules_version = '2';
     service cloud.firestore {
       match /databases/{database}/documents {
         match /{document=**} {
           allow read, write: if true;
         }
       }
     }
     ```

5. **Run the app**
   ```bash
   flutter run
   ```

### Building

| Platform | Command |
|----------|---------|
| **Android APK** | `flutter build apk --release` |
| **Android App Bundle** | `flutter build appbundle --release` |
| **Web** | `flutter build web --release` |
| **Windows** | `flutter build windows --release` |

## Firebase Configuration

Seyra uses the following Firebase services:

| Service | Purpose |
|---------|---------|
| **Firebase Auth** | User authentication (email/password, internally mapped from @username) |
| **Cloud Firestore** | Messages, chats, users, call signaling, group management |

### Firestore Schema

```
users/
  {uid}
    username: "@john"              # Unique @username
    displayName: "John"            # Display name (without @)
    profilePic: "https://..."      # Profile picture URL
    chats: ["chatId1", "chatId2"]  # List of chat IDs
    isAnonymous: false              # Anonymous mode flag

chats/
  {chatId}
    users: ["uid1", "uid2"]        # Participants
    type: "Private" | "Group"      # Chat type
    displayName: "Group Name"      # Group name
    lastMessageAt: Timestamp       # Last message timestamp
    typingStatus: { "uid": true }  # Typing indicators

chats/{chatId}/messages/
  {messageId}
    senderId: "uid"
    createdAt: Timestamp
    textMessage: "Hello"
    mediaMessage: "https://..."

users/{uid}/calls/
  {callId}
    contactId: "uid"
    callType: "Audio" | "Video"
    direction: "Incoming" | "Outgoing"
    timestamp: Timestamp

users/{uid}/Room/{roomId}          # WebRTC call signaling
  offer / answer / callerCandidates / calleeCandidates

groupCalls/{groupId}               # Group call coordination
  participants / signals
```

## How Authentication Works

Seyra uses a **username-based auth** system on top of Firebase:

1. The user picks a `@username` (minimum 4 characters, alphanumeric + underscore) and a password.
2. Internally, the username is converted to a synthetic email: `seyra_{username}@seyra.auth`.
3. Firebase Auth handles the actual authentication using this synthetic email.
4. The `@username` is stored in Firestore and displayed throughout the app.
5. **Username uniqueness** is enforced by querying Firestore before account creation.
6. **Display names** are stored without the `@` prefix for cleaner presentation.

This means **no email address or phone number is needed** to use Seyra.

---

## Security

### Authentication & Identity

| Feature | Description |
|---------|-------------|
| **Username-based auth** | Users authenticate with `@username` + password. No email or phone number is collected or stored. |
| **Synthetic email mapping** | Usernames are converted to internal emails (`seyra_{name}@seyra.auth`) so Firebase Auth handles credentials without exposing real emails. |
| **Unique username enforcement** | Firestore query checks username uniqueness before account creation. Each `@username` is globally unique. |
| **Password hashing** | Passwords are hashed and managed by Firebase Auth (bcrypt + salting). Plaintext passwords are never stored. |

### App Lock & Data Protection

| Feature | Description |
|---------|-------------|
| **Passcode lock** | Optional 4-digit passcode required on app open. Stored in Flutter Secure Storage (hardware-backed encryption). |
| **Biometric lock** | Fingerprint / Face ID unlock on supported devices. |
| **Panic wipe** | Entering `0000` on the lock screen instantly wipes all local data (Hive, SharedPreferences, Secure Storage) and signs out. |
| **Secure Storage** | Sensitive data (passcodes) stored via `flutter_secure_storage`, which uses Keychain (iOS), KeyStore (Android), and similar OS-level encryption on other platforms. |

### Messaging & Calls

| Feature | Description |
|---------|-------------|
| **Message deletion** | Users can unsend/delete individual messages for all participants. |
| **Chat history removal** | Entire chat histories can be permanently deleted. |
| **Secure identity purge** | Cryptographic keys and chat documents can be deleted to break encrypted channels. |
| **WebRTC calls** | Audio/video calls use WebRTC with STUN/TURN servers for NAT traversal. Call signaling is encrypted via Firestore. |
| **Typing indicators** | Real-time typing status without exposing message content. |

### Data Minimization

| Principle | Implementation |
|-----------|---------------|
| **No phone numbers** | Auth is username-only; phone contacts are matched locally but never uploaded. |
| **No email collection** | Synthetic emails are internal only; users never see or provide real email addresses. |
| **Anonymous mode** | Users can toggle anonymous mode to hide their identity in chats. |
| **Local-first contacts** | Device contacts are matched against Firestore user records locally; raw contact data is not stored on the server. |

### Firestore Security Rules (Production)

For production, use restrictive Firestore rules:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    match /chats/{chatId} {
      allow read, write: if request.auth != null
        && request.auth.uid in resource.data.users;
      allow create: if request.auth != null;
    }
    match /chats/{chatId}/messages/{messageId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow delete: if request.auth != null
        && request.auth.uid == resource.data.senderId;
    }
  }
}
```

### Production Checklist

- [ ] Set Firestore rules to authenticated-only access
- [ ] Enable Firebase App Check to prevent abuse
- [ ] Set up Firestore indexes for common queries
- [ ] Configure Firebase Security Rules for Storage (if used)
- [ ] Enable Firebase Auth email verification (optional)
- [ ] Review and restrict CORS policies for web deployment
- [ ] Set up monitoring and alerting in Firebase Console

---

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License -- see the [LICENSE](LICENSE) file for details.

---

<div align="center">

**Built with Flutter + Firebase**

</div>

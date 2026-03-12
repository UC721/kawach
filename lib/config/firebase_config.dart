import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase configuration.
/// Replace the placeholder values below with your actual
/// Firebase project credentials from the Firebase Console.
///
/// Steps:
/// 1. Create a Firebase project at https://console.firebase.google.com
/// 2. Add an Android app (package: com.kawach.app)
/// 3. Download google-services.json → android/app/
/// 4. Add an iOS app → download GoogleService-Info.plist → ios/Runner/
/// 5. Enable Authentication (Email + Phone)
/// 6. Create Firestore database (production mode)
/// 7. Enable Storage bucket
/// 8. Enable Cloud Messaging
class FirebaseConfig {
  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: _currentPlatform,
    );
  }

  static FirebaseOptions get _currentPlatform {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return _androidOptions;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return _iosOptions;
    }
    return _androidOptions;
  }

  // ── REPLACE THESE WITH YOUR REAL CREDENTIALS ─────────────────
  static const FirebaseOptions _androidOptions = FirebaseOptions(
    apiKey: 'YOUR_ANDROID_API_KEY',
    appId: 'YOUR_ANDROID_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
  );

  static const FirebaseOptions _iosOptions = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
    iosBundleId: 'com.kawach.app',
  );
}

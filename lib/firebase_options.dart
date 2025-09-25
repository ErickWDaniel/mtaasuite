// File generated for Firebase configuration
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static FirebaseOptions get web => FirebaseOptions(
    apiKey: dotenv.env['FIREBASE_WEB_API_KEY'] ?? 'your_web_api_key_here',
    appId: dotenv.env['FIREBASE_WEB_APP_ID'] ?? 'your_web_app_id_here',
    messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? 'your_sender_id',
    projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? 'your_project_id',
    authDomain: dotenv.env['FIREBASE_AUTH_DOMAIN'] ?? 'your_project.firebaseapp.com',
    storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? 'your_project.appspot.com',
    measurementId: dotenv.env['FIREBASE_MEASUREMENT_ID'] ?? 'G-MEASUREMENT_ID',
    databaseURL: dotenv.env['FIREBASE_DATABASE_URL'] ?? 'https://your_project-default-rtdb.firebaseio.com',
  );

  static FirebaseOptions get android => FirebaseOptions(
    apiKey: dotenv.env['FIREBASE_ANDROID_API_KEY'] ?? 'your_android_api_key_here',
    appId: dotenv.env['FIREBASE_ANDROID_APP_ID'] ?? 'your_android_app_id_here',
    messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? 'your_sender_id',
    projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? 'your_project_id',
    storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? 'your_project.appspot.com',
    databaseURL: dotenv.env['FIREBASE_DATABASE_URL'] ?? 'https://your_project-default-rtdb.firebaseio.com',
  );

  static FirebaseOptions get ios => FirebaseOptions(
    apiKey: dotenv.env['FIREBASE_IOS_API_KEY'] ?? 'your_ios_api_key_here',
    appId: dotenv.env['FIREBASE_IOS_APP_ID'] ?? 'your_ios_app_id_here',
    messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? 'your_sender_id',
    projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? 'your_project_id',
    storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? 'your_project.appspot.com',
    databaseURL: dotenv.env['FIREBASE_DATABASE_URL'] ?? 'https://your_project-default-rtdb.firebaseio.com',
    iosBundleId: dotenv.env['FIREBASE_IOS_BUNDLE_ID'] ?? 'your_bundle_id',
  );
}

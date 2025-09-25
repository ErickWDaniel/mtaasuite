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
    apiKey: 'AIzaSyDLFB6Sj32tZDkgb4t2R5XRFgxIADMWLYw',
    appId: '1:800818846322:web:b9c0eb50212ec21web',
    messagingSenderId: '800818846322',
    projectId: 'mtaasuite',
    authDomain: 'mtaasuite.firebaseapp.com',
    storageBucket: 'mtaasuite.firebasestorage.app',
    measurementId: 'G-MEASUREMENT_ID',
    databaseURL: 'https://mtaasuite-default-rtdb.firebaseio.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDLFB6Sj32tZDkgb4t2R5XRFgxIADMWLYw',
    appId: '1:800818846322:android:67ae32f50212ec21b9c0eb',
    messagingSenderId: '800818846322',
    projectId: 'mtaasuite',
    storageBucket: 'mtaasuite.firebasestorage.app',
    databaseURL: 'https://mtaasuite-default-rtdb.firebaseio.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDLFB6Sj32tZDkgb4t2R5XRFgxIADMWLYw',
    appId: '1:800818846322:ios:b9c0eb50212ec21',
    messagingSenderId: '800818846322',
    projectId: 'mtaasuite',
    storageBucket: 'mtaasuite.firebasestorage.app',
    databaseURL: 'https://mtaasuite-default-rtdb.firebaseio.com',
    iosBundleId: 'tz.co.mtaasuite.mtaasuite',
  );
}

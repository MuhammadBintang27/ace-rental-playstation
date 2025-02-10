// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
        return macos;
      case TargetPlatform.windows:
        return windows;
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBRCzoKDKDnx3V7GXWkoz5MUjL7M7KL1YI',
    appId: '1:79315975071:web:d66e2d1e0744897fe2dbaa',
    messagingSenderId: '79315975071',
    projectId: 'ace-rental-playstation',
    authDomain: 'ace-rental-playstation.firebaseapp.com',
    storageBucket: 'ace-rental-playstation.firebasestorage.app',
    measurementId: 'G-MP0RXRX8HC',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCJwOHhJmY8NN05IRyBEkcxsmN4fpqMknY',
    appId: '1:79315975071:android:a3d57d23607ea50ee2dbaa',
    messagingSenderId: '79315975071',
    projectId: 'ace-rental-playstation',
    storageBucket: 'ace-rental-playstation.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC2qFmG27owVyXGcvaBe-QvXJNed3LHNfY',
    appId: '1:79315975071:ios:747b6d3c3a466a5fe2dbaa',
    messagingSenderId: '79315975071',
    projectId: 'ace-rental-playstation',
    storageBucket: 'ace-rental-playstation.firebasestorage.app',
    iosBundleId: 'com.example.aceRental',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyC2qFmG27owVyXGcvaBe-QvXJNed3LHNfY',
    appId: '1:79315975071:ios:747b6d3c3a466a5fe2dbaa',
    messagingSenderId: '79315975071',
    projectId: 'ace-rental-playstation',
    storageBucket: 'ace-rental-playstation.firebasestorage.app',
    iosBundleId: 'com.example.aceRental',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBRCzoKDKDnx3V7GXWkoz5MUjL7M7KL1YI',
    appId: '1:79315975071:web:e5a82088e42d7f65e2dbaa',
    messagingSenderId: '79315975071',
    projectId: 'ace-rental-playstation',
    authDomain: 'ace-rental-playstation.firebaseapp.com',
    storageBucket: 'ace-rental-playstation.firebasestorage.app',
    measurementId: 'G-QZE4TKEXVM',
  );
}

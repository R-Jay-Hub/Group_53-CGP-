import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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

  // Web

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: '',
    authDomain: 'brewmind-cafe.firebaseapp.com',
    projectId: 'brewmind-cafe',
    storageBucket: 'brewmind-cafe.firebasestorage.app',
    messagingSenderId: '329523651010',
    appId: '1:329523651010:web:4c380d3bbd93c01969b65b',
    measurementId: 'G-12Z33QPQEM',
  );

  // Andriod
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: '',
    authDomain: 'brewmind-cafe.firebaseapp.com',
    projectId: 'brewmind-cafe',
    storageBucket: 'brewmind-cafe.firebasestorage.app',
    messagingSenderId: '329523651010',
    appId: '1:329523651010:android:REPLACE_WITH_ANDROID_APP_ID',
  );

  // ios
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: '',
    authDomain: 'brewmind-cafe.firebaseapp.com',
    projectId: 'brewmind-cafe',
    storageBucket: 'brewmind-cafe.firebasestorage.app',
    messagingSenderId: '329523651010',
    appId: '1:329523651010:ios:REPLACE_WITH_IOS_APP_ID',
    iosBundleId: 'com.brewmind.app',
  );

  // macOS
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: '',
    authDomain: 'brewmind-cafe.firebaseapp.com',
    projectId: 'brewmind-cafe',
    storageBucket: 'brewmind-cafe.firebasestorage.app',
    messagingSenderId: '329523651010',
    appId: '1:329523651010:ios:REPLACE_WITH_IOS_APP_ID',
    iosBundleId: 'com.brewmind.app',
  );

  // Windows
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: '',
    authDomain: 'brewmind-cafe.firebaseapp.com',
    projectId: 'brewmind-cafe',
    storageBucket: 'brewmind-cafe.firebasestorage.app',
    messagingSenderId: '329523651010',
    appId: '1:329523651010:web:4c380d3bbd93c01969b65b',
    measurementId: 'G-12Z33QPQEM',
  );
}

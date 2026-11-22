// File generated for spot-dev-17336 environment.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
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
          'DefaultFirebaseOptions have not been configured for linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAvWZpOmVqXxJhpcnuUod-kGn_JEFN7XFE',
    appId: '1:581004817275:web:59c8d43a4c4aeae7fd43de',
    messagingSenderId: '581004817275',
    projectId: 'spot-dev-17336',
    authDomain: 'spot-dev-17336.firebaseapp.com',
    storageBucket: 'spot-dev-17336.firebasestorage.app',
    measurementId: 'G-E4TN12XLED',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA4y31k_MB0Ec0GjKOxv-YkifYM1zAuL1o',
    appId: '1:581004817275:android:c4162871a79aec83fd43de',
    messagingSenderId: '581004817275',
    projectId: 'spot-dev-17336',
    storageBucket: 'spot-dev-17336.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAIgydeLOwFOdit_UjQbcDBd7INpn51u7A',
    appId: '1:581004817275:ios:239b4390171357b6fd43de',
    messagingSenderId: '581004817275',
    projectId: 'spot-dev-17336',
    storageBucket: 'spot-dev-17336.firebasestorage.app',
    iosBundleId: 'com.elnazer-edu.elnazer',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAIgydeLOwFOdit_UjQbcDBd7INpn51u7A',
    appId: '1:581004817275:ios:239b4390171357b6fd43de',
    messagingSenderId: '581004817275',
    projectId: 'spot-dev-17336',
    storageBucket: 'spot-dev-17336.firebasestorage.app',
    iosBundleId: 'com.elnazer-edu.elnazer',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAvWZpOmVqXxJhpcnuUod-kGn_JEFN7XFE',
    appId: '1:581004817275:web:59c8d43a4c4aeae7fd43de',
    messagingSenderId: '581004817275',
    projectId: 'spot-dev-17336',
    authDomain: 'spot-dev-17336.firebaseapp.com',
    storageBucket: 'spot-dev-17336.firebasestorage.app',
    measurementId: 'G-E4TN12XLED',
  );
}

// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD6GnSQDGGEFDyy5L7jJP9wjgdnp6CIsno',
    appId: '1:308150028417:web:7c62ce563649d789f72580',
    messagingSenderId: '308150028417',
    projectId: 'flutter-dashboard',
    authDomain: 'flutter-dashboard.firebaseapp.com',
    storageBucket: 'flutter-dashboard.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDF2MqINV6IYJXEm5ag6epF3VIMGb92yiU',
    appId: '1:308150028417:android:013a57781a783085f72580',
    messagingSenderId: '308150028417',
    projectId: 'flutter-dashboard',
    storageBucket: 'flutter-dashboard.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD_muVWfyvPVe1tA1BkGT-n9wPlUF0QzgY',
    appId: '1:308150028417:ios:bfa7cf7c0a0daef8f72580',
    messagingSenderId: '308150028417',
    projectId: 'flutter-dashboard',
    storageBucket: 'flutter-dashboard.appspot.com',
    androidClientId:
        '308150028417-416s3rumsec22qlgm710vd3utvmnvr9r.apps.googleusercontent.com',
    iosBundleId: 'com.example.appFlutter',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyD_muVWfyvPVe1tA1BkGT-n9wPlUF0QzgY',
    appId: '1:308150028417:ios:bfa7cf7c0a0daef8f72580',
    messagingSenderId: '308150028417',
    projectId: 'flutter-dashboard',
    storageBucket: 'flutter-dashboard.appspot.com',
    androidClientId:
        '308150028417-416s3rumsec22qlgm710vd3utvmnvr9r.apps.googleusercontent.com',
    iosBundleId: 'com.example.appFlutter',
  );
}

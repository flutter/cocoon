// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:google_sign_in_web/google_sign_in_web.dart';

/// Widget that users can click to initiate the Sign In process.
class SignInButton extends StatefulWidget {
  const SignInButton({super.key});

  @override
  State<StatefulWidget> createState() => _SignInButtonState();
}

class _SignInButtonState extends State<SignInButton> {
  late GoogleSignInPlugin _googleSignInPlugin;

  static Future<void>? _initializing;

  Future<void> _initGoogleSignIn() async {
    if (_initializing != null) return _initializing;
    _initializing = GoogleSignInPlatform.instance.initWithParams(
      const SignInInitParameters(scopes: []),
    );
  }

  @override
  void initState() {
    super.initState();
    _initGoogleSignIn();

    // This appears to be the only way to get the userDataEvents stream -
    // which is needed to convert users to Firebase Auth
    _googleSignInPlugin = GoogleSignInPlatform.instance as GoogleSignInPlugin;
    _googleSignInPlugin.userDataEvents!.listen((data) async {
      if (data != null) {
        final auth = FirebaseAuth.instance;
        final credential = GoogleAuthProvider.credential(idToken: data.idToken);
        try {
          final cred = await auth.signInWithCredential(credential);
          print('${cred.user?.email} signed in');
        } catch (e) {
          print('error signing into firebase');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _googleSignInPlugin.renderButton();
  }
}

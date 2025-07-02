// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:google_sign_in/google_sign_in.dart'
    show
        GoogleSignIn,
        GoogleSignInAuthenticationEventSignIn,
        GoogleSignInAuthenticationEventSignOut;

import 'package:google_sign_in_web/web_only.dart' as gsw;

/// Widget that users can click to initiate the Sign In process.
class SignInButton extends StatefulWidget {
  const SignInButton({super.key});

  @override
  State<StatefulWidget> createState() => _SignInButtonState();
}

class _SignInButtonState extends State<SignInButton> {
  static Future<void>? _initializing;

  Future<void> _initGoogleSignIn() async {
    if (_initializing != null) return _initializing;

    _initializing = GoogleSignIn.instance.initialize();

    GoogleSignIn.instance.authenticationEvents.listen((data) async {
      try {
        final user = switch (data) {
          GoogleSignInAuthenticationEventSignIn() => data.user,
          GoogleSignInAuthenticationEventSignOut() => null,
        };
        if (user == null) {
          print('signed out');
          return;
        }
        final fireAuth = FirebaseAuth.instance;
        final credential = GoogleAuthProvider.credential(
          idToken: user.authentication.idToken,
        );
        final cred = await fireAuth.signInWithCredential(credential);
        print('${cred.user!.email} signed in');
      } catch (e) {
        print('error signing into firebase');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initGoogleSignIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return gsw.renderButton();
        }
        return const CircularProgressIndicator();
      },
    );
  }
}

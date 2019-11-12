// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'service/google_authentication.dart';

/// Widget for displaying sign in information for the current user.
///
/// If logged in, it will display the user's avatar. Clicking it opens a dropdown for logging out.
/// Otherwise, it a sign in button will show.
class SignInButton extends StatefulWidget {
  const SignInButton({@required this.authService, Key key}) : super(key: key);

  final GoogleSignInService authService;

  @override
  _SignInButtonState createState() => _SignInButtonState();
}

class _SignInButtonState extends State<SignInButton> {
  @override
  Widget build(BuildContext context) {
    final GoogleSignInService authService = widget.authService;

    if (authService.isAuthenticated) {
      return PopupMenuButton<Future<void>>(
        child: Image.network(authService.user.photoUrl),
        itemBuilder: (BuildContext context) => <PopupMenuEntry<Future<void>>>[
          PopupMenuItem<Future<void>>(
            value: authService.signOut(),
            child: const Text('Log out'),
          ),
        ],
      );
    }

    return FlatButton(
      child: const Text(
        'Sign in',
        style: TextStyle(color: Colors.white),
      ),
      onPressed: () => authService.signIn(),
    );
  }
}

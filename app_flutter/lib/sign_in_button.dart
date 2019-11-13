// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'service/google_authentication.dart';

/// Widget for displaying sign in information for the current user.
///
/// If logged in, it will display the user's avatar. Clicking it opens a dropdown for logging out.
/// Otherwise, a sign in button will show.
class SignInButton extends StatelessWidget {
  const SignInButton({@required this.authService, Key key}) : super(key: key);

  final GoogleSignInService authService;

  @override
  Widget build(BuildContext context) {
    if (authService.isAuthenticated) {
      return PopupMenuButton<String>(
        child: Image.network(authService.user.photoUrl),
        offset: const Offset(0, 50),
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          const PopupMenuItem<String>(
            value: 'logout',
            child: Text('Log out'),
          ),
        ],
        onSelected: (String value) {
          if (value == 'logout') {
            authService.signOut();
          }
        },
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

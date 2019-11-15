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
    return FutureBuilder<bool>(
      future: authService.isAuthenticated,
      builder: (BuildContext context, AsyncSnapshot<bool> isAuthenticated) {
        /// On sign out, there's a second where the user is null before isAuthenticated catches up.
        if (isAuthenticated.data && authService.user != null)
          return PopupMenuButton<String>(
            // TODO(chillers): Switch to use avatar widget provided by google_sign_in plugin
            child: Image.network(authService.user?.photoUrl),
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
        else
          return FlatButton(
            child: const Text(
              'Sign in',
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () => authService.signIn(),
          );
      },
    );
  }
}

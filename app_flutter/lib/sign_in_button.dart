// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:app_flutter/canvaskit_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_progress_button/flutter_progress_button.dart';

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
      builder: (_, AsyncSnapshot<bool> isAuthenticated) {
        /// On sign out, there's a second where the user is null before isAuthenticated catches up.
        if (isAuthenticated.data == true && authService.user != null) {
          return PopupMenuButton<String>(
            // TODO(chillers): Show a Network Image. https://github.com/flutter/flutter/issues/45955
            // CanvasKit currently cannot render a NetworkImage because of CORS issues.
            child: CanvasKitWidget(
              canvaskit: Padding(
                child: Text(authService.user.email),
                padding: const EdgeInsets.only(right: 10.0, top: 20.0),
              ),
              // TODO(chillers): Switch to use avatar widget provided by google_sign_in plugin
              other: Image.network(authService.user?.photoUrl),
            ),
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
          onPressed: authService.signIn,
        );
      },
    );
  }
}

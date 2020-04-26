// Copyright (c) 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../service/google_authentication.dart';
import 'web_image.dart';

enum _SignInButtonAction { logout }

/// Widget for displaying sign in information for the current user.
///
/// If logged in, it will display the user's avatar. Clicking it opens a dropdown for logging out.
/// Otherwise, a sign in button will show.
class SignInButton extends StatelessWidget {
  const SignInButton({
    Key key,
    this.colorBrightness,
  }) : super(key: key);

  final Brightness colorBrightness;

  @override
  Widget build(BuildContext context) {
    final GoogleSignInService authService = Provider.of<GoogleSignInService>(context);
    return FutureBuilder<bool>(
      future: authService.isAuthenticated,
      builder: (BuildContext context, AsyncSnapshot<bool> isAuthenticated) {
        /// On sign out, there's a second where the user is null before isAuthenticated catches up.
        if (isAuthenticated.data == true && authService.user != null) {
          return PopupMenuButton<_SignInButtonAction>(
            // TODO(chillers): Show a Network Image. https://github.com/flutter/flutter/issues/45955
            // CanvasKit currently cannot render a NetworkImage because of CORS issues.
            child: WebImage(
              // TODO(chillers): Switch to use avatar widget provided by google_sign_in plugin
              imageUrl: authService.user?.photoUrl,
              placeholder: (BuildContext context, String url) => Padding(
                child: Text(authService.user.email),
                padding: const EdgeInsets.only(right: 10.0, top: 20.0),
              ),
            ),
            offset: const Offset(0, 50),
            itemBuilder: (BuildContext context) => <PopupMenuEntry<_SignInButtonAction>>[
              const PopupMenuItem<_SignInButtonAction>(
                value: _SignInButtonAction.logout,
                child: Text('Log out'),
              ),
            ],
            onSelected: (_SignInButtonAction value) {
              switch (value) {
                case _SignInButtonAction.logout:
                  authService.signOut();
                  break;
              }
            },
          );
        }
        return FlatButton(
          child: const Text('SIGN IN'),
          colorBrightness: colorBrightness ?? Theme.of(context).brightness,
          onPressed: authService.signIn,
        );
      },
    );
  }
}

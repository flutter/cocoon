// Copyright 2019 The Flutter Authors. All rights reserved.
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
class SignInButton extends StatefulWidget {
  const SignInButton({
    Key key,
    this.colorBrightness,
  }) : super(key: key);

  final Brightness colorBrightness;

  @override
  State createState() => _SignInButtonState();
}

class _SignInButtonState extends State<SignInButton> {
  GoogleSignInService authService;
  bool isAuthenticated;

  void _authListen() {
    setState(() async {
      isAuthenticated = await authService.isAuthenticated;
    });
  }

  @override
  void initState() {
    super.initState();
    isAuthenticated = false;
    authService = Provider.of<GoogleSignInService>(context);
    authService.addListener(_authListen);
    authService.isAuthenticated.then((_) => _authListen());
  }

  @override
  void dispose() {
    authService.removeListener(_authListen);
    authService.dispose();
    authService = null;
    isAuthenticated = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color textButtonForeground =
        (widget.colorBrightness ?? Theme.of(context).brightness) == Brightness.dark ? Colors.white : Colors.black87;

    /// On sign out, there's a second where the user is null before isAuthenticated catches up.
    if (isAuthenticated && authService.user != null) {
      return PopupMenuButton<_SignInButtonAction>(
        child: WebImage(
          // TODO(chillers): Switch to use avatar widget provided by google_sign_in plugin
          imageUrl: authService.user?.photoUrl,
          placeholder: Padding(
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
    return TextButton(
      child: const Text('SIGN IN'),
      style: TextButton.styleFrom(primary: textButtonForeground),
      onPressed: authService.signIn,
    );
  }
}

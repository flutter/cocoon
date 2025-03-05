// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/widgets.dart';
import 'package:provider/provider.dart';

import '../service/google_authentication.dart';
import 'sign_in_button/sign_in_button.dart';

enum _SignInButtonAction { logout }

/// Widget for displaying sign in information for the current user.
///
/// If logged in, it will display the user's avatar. Clicking it opens a dropdown for logging out.
/// Otherwise, a sign in button will show.
class UserSignIn extends StatelessWidget {
  const UserSignIn({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<GoogleSignInService>(context);

    // Listen to the changes of `authService` to re-render.
    return AnimatedBuilder(
      animation: authService,
      builder: (BuildContext context, _) {
        if (authService.user != null) {
          return PopupMenuButton<_SignInButtonAction>(
            offset: const Offset(0, 50),
            itemBuilder:
                (BuildContext context) => <PopupMenuEntry<_SignInButtonAction>>[
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
            iconSize: Scaffold.of(context).appBarMaxHeight,
            icon: Builder(
              builder: (BuildContext context) {
                if (!kIsWeb &&
                    Platform.environment.containsKey('FLUTTER_TEST')) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 10.0, top: 20.0),
                    child: Text(authService.user!.email),
                  );
                }
                return GoogleUserCircleAvatar(identity: authService.user!);
              },
            ),
          );
        }
        return const SignInButton();
      },
    );
  }
}

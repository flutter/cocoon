// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

import '../service/firebase_auth.dart';
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
    final authService = Provider.of<FirebaseAuthService>(context);

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
            onSelected: (_SignInButtonAction value) async {
              switch (value) {
                case _SignInButtonAction.logout:
                  await authService.signOut();
              }
            },
            iconSize: Scaffold.of(context).appBarMaxHeight,
            icon: Builder(
              builder: (BuildContext context) {
                if (!kIsWeb &&
                    Platform.environment.containsKey('FLUTTER_TEST')) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 10.0, top: 20.0),
                    child: Text(authService.user?.email ?? 'user@example.com'),
                  );
                }
                return GoogleUserCircleAvatar(
                  identity: FirebaseUserIdentity(authService.user!),
                );
              },
            ),
          );
        }
        return const SignInButton();
      },
    );
  }
}

class FirebaseUserIdentity implements GoogleIdentity {
  FirebaseUserIdentity(this.user);

  final User user;

  @override
  String? get displayName => user.displayName;

  @override
  String get email => user.email!;

  @override
  String get id => '1234';

  @override
  // TODO: implement photoUrl
  String? get photoUrl => user.photoURL;

  @override
  String? get serverAuthCode => '';
}

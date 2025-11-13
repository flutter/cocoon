// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

import '../service/firebase_auth.dart';
import 'sign_in_button/sign_in_button.dart';

enum _SignInButtonAction {
  logout,
  linkGithub,
  unlinkGithub,
  linkGoogle,
  unlinkGoogle,
}

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
            itemBuilder: (BuildContext context) =>
                _buildLinkUnlinkMenuItem(authService.user!.providerData),
            onSelected: (_SignInButtonAction value) async {
              switch (value) {
                case _SignInButtonAction.logout:
                  await authService.signOut();
                  break;
                case _SignInButtonAction.linkGithub:
                  await authService.linkWithGithub();
                  break;
                case _SignInButtonAction.unlinkGithub:
                  await authService.unlinkProvider(GithubAuthProvider());
                  break;
                case _SignInButtonAction.linkGoogle:
                  await authService.linkWithGoogle();
                  break;
                case _SignInButtonAction.unlinkGoogle:
                  await authService.unlinkProvider(GoogleAuthProvider());
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
                    child: Text(authService.user?.email ?? 'user@example.com'),
                  );
                }
                return CircleAvatar(
                  foregroundImage: CachedNetworkImageProvider(
                    authService.user!.photoURL!,
                  ),
                  child: Text(
                    <String?>[
                          authService.user!.displayName,
                          authService.user!.email,
                          '-',
                        ]
                        .firstWhere(
                          (String? str) =>
                              str != null && str.trimLeft().isNotEmpty,
                        )!
                        .trimLeft()
                        .split(' ')
                        .map((String str) => str[0])
                        .join()
                        .toUpperCase(),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),
          );
        }
        return const SignInButton();
      },
    );
  }

  List<PopupMenuItem<_SignInButtonAction>> _buildLinkUnlinkMenuItem(
    List<UserInfo> providerData,
  ) {
    final items = <PopupMenuItem<_SignInButtonAction>>[];
    if (providerData.isNotEmpty && providerData.length <= 2) {
      // One provider linked to firebase user. Show link option for the other.
      if (providerData.length == 1) {
        // Linked provider is Google. Show Link GitHub Account option.
        if (providerData.first.providerId == GoogleAuthProvider.PROVIDER_ID) {
          items.add(
            const PopupMenuItem<_SignInButtonAction>(
              value: _SignInButtonAction.linkGithub,
              child: Text('Link GitHub Account'),
            ),
          );
        }
        // Linked provider is Github. Show Link Google Account option.
        else if (providerData.first.providerId ==
            GithubAuthProvider.PROVIDER_ID) {
          items.add(
            const PopupMenuItem<_SignInButtonAction>(
              value: _SignInButtonAction.linkGoogle,
              child: Text('Link Google Account'),
            ),
          );
        }
      }
      // Two providers linked. Show unlink option.
      else if (providerData.length == 2) {
        // The only way to figure out which account was linked is to check order.
        // If last linked provider is Google. Allow unlinking Google Account.
        if (providerData.last.providerId == GoogleAuthProvider.PROVIDER_ID) {
          items.add(
            const PopupMenuItem<_SignInButtonAction>(
              value: _SignInButtonAction.unlinkGoogle,
              child: Text('Unlink Google Account'),
            ),
          );
        } // If last linked provider is Github. Allow unlinking Github Account.
        else if (providerData.last.providerId ==
            GithubAuthProvider.PROVIDER_ID) {
          items.add(
            const PopupMenuItem<_SignInButtonAction>(
              value: _SignInButtonAction.unlinkGithub,
              child: Text('Unlink GitHub Account'),
            ),
          );
        }
      }
    }
    // Always show logout option.
    items.add(
      const PopupMenuItem<_SignInButtonAction>(
        value: _SignInButtonAction.logout,
        child: Text('Log out'),
      ),
    );
    return items;
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
}

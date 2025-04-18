// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:flutter/material.dart';

import '../../consts/client_id.dart';

/// Widget that users can click to initiate the Sign In process.
class SignInButton extends StatelessWidget {
  const SignInButton({super.key});

  @override
  Widget build(BuildContext context) {
    return const GoogleSignInButton(
      loadingIndicator: CircularProgressIndicator(),
      clientId: signInClientId,
    );
  }
}

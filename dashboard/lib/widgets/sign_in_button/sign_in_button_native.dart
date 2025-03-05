// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../service/google_authentication.dart';

/// Widget that users can click to initiate the Sign In process.
class SignInButton extends StatelessWidget {
  const SignInButton({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<GoogleSignInService>(context);
    final textButtonForeground = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black87;

    return TextButton(
      style: TextButton.styleFrom(foregroundColor: textButtonForeground),
      onPressed: authService.signIn,
      child: const Text('SIGN IN'),
    );
  }
}

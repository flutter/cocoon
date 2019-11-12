import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_sign_in/widgets.dart';

import 'service/google_authentication.dart';
import 'state/flutter_build.dart';

/// Widget for displaying sign in information for the current user.
///
/// If logged in, it will display the user's avatar. Clicking it opens a dropdown for logging out.
/// Otherwise, it a sign in button will show.
class SignInButton extends StatefulWidget {
  const SignInButton({@required this.buildState, Key key}) : super(key: key);

  final FlutterBuildState buildState;

  @override
  _SignInButtonState createState() => _SignInButtonState();
}

class _SignInButtonState extends State<SignInButton> {
  @override
  Widget build(BuildContext context) {
    final GoogleSignInService authService = widget.buildState.authService;

    if (authService.isAuthenticated) {
      return PopupMenuButton<Future<void>>(
        child: GoogleUserCircleAvatar(
          identity: authService.user,
        ),
        itemBuilder: (BuildContext context) => <PopupMenuEntry<Future<void>>>[
          PopupMenuItem<Future<void>>(
            value: widget.buildState.signOut(),
            child: const Text('Log out'),
          ),
        ],
      );
    }

    return FlatButton(
      child: const Text(
        'Sign in',
        style: TextStyle(color: Colors.white),
      ),
      onPressed: () => widget.buildState.signIn(),
    );
  }
}

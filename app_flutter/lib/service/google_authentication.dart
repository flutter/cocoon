import 'package:app_flutter/service/authentication.dart';
import 'package:google_sign_in_all/google_sign_in_all.dart';

class GoogleAuthenticationService extends AuthenticationService {
  GoogleAuthenticationService({GoogleSignIn googleSignIn})
      : _googleSignIn = googleSignIn ??
            setupGoogleSignIn(
              scopes: <String>[
                'https://www.googleapis.com/auth/userinfo.email',
                'https://www.googleapis.com/auth/userinfo.profile',
              ],
              webClientId: 'github blocks me from putting you here :(',
            ),
        super();

  GoogleSignIn _googleSignIn;

  AuthCredentials credentials;

  GoogleAccount user;

  @override
  Future<bool> signIn() {
    return null;
  }
}

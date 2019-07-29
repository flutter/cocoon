import 'package:appengine/appengine.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import '../model/appengine/service_account_info.dart';

/// A provider for Oauth2 tokens from Service Account JSON.
class AccessTokenProvider {
  /// Creates a new Access Token provider.
  const AccessTokenProvider();

  /// Returns an OAuth 2.0 access token for the device lab service account.
  Future<AccessToken> createAccessToken(
    ClientContext context, {
    @required Map<String, dynamic> serviceAccountJson,
    List<String> scopes = const <String>['https://www.googleapis.com/auth/cloud-platform'],
  }) async {
    if (context.isDevelopmentEnvironment) {
      // No auth token needed.
      return null;
    }

    final ServiceAccountInfo accountInfo = ServiceAccountInfo.fromJson(serviceAccountJson);
    final http.Client httpClient = http.Client();
    try {
      final AccessCredentials credentials = await obtainAccessCredentialsViaServiceAccount(
        accountInfo.asServiceAccountCredentials(),
        scopes,
        httpClient,
      );
      return credentials.accessToken;
    } finally {
      httpClient.close();
    }
  }
}

import 'package:appengine/appengine.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

import '../datastore/cocoon_config.dart';
import '../model/appengine/service_account_info.dart';

/// A provider for Oauth2 tokens from Service Account JSON.
class AccessTokenProvider {
  /// Creates a new Access Token provider.
  const AccessTokenProvider(this.config) : assert(config != null);

  /// The Cocoon configuration.
  final Config config;

  /// Returns an OAuth 2.0 access token for the device lab service account.
  Future<AccessToken> createAccessToken(
    ClientContext context, {
    List<String> scopes = const <String>['https://www.googleapis.com/auth/cloud-platform'],
  }) async {
    if (context.isDevelopmentEnvironment) {
      // No auth token needed.
      return null;
    }

    final ServiceAccountInfo serviceAccount = await config.deviceLabServiceAccount;
    final http.Client httpClient = http.Client();
    try {
      final AccessCredentials credentials = await obtainAccessCredentialsViaServiceAccount(
        serviceAccount.asServiceAccountCredentials(),
        scopes,
        httpClient,
      );
      return credentials.accessToken;
    } finally {
      httpClient.close();
    }
  }
}

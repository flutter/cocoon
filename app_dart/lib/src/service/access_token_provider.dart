import 'package:appengine/appengine.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import '../datastore/cocoon_config.dart';
import '../model/appengine/service_account_info.dart';

class AccessTokenProvider {
  const AccessTokenProvider(this.config);

  final Config config;

  /// Returns an OAuth 2.0 access token for the device lab service account.
  Future<AccessToken> createAccessToken(
    ClientContext context, {
    @required Future<Map<String, dynamic>> serviceAccountJson,
    List<String> scopes = const <String>['https://www.googleapis.com/auth/cloud-platform'],
  }) async {
    // if (context.isDevelopmentEnvironment) {
    //   // No auth token needed.
    //   return null;
    // }

    final Map<String, dynamic> json = await serviceAccountJson;
    final ServiceAccountInfo accountInfo = ServiceAccountInfo.fromJson(json);
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

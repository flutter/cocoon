// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:corsac_jwt/corsac_jwt.dart';
import 'package:github/github.dart';
import 'package:graphql/client.dart';
import 'package:http/http.dart' as http;
import 'package:neat_cache/cache_provider.dart';
import 'package:neat_cache/neat_cache.dart';

import '../foundation/providers.dart';
import '../service/secrets.dart';
import 'github_service.dart';
import 'log.dart';

/// Configuration for the autosubmit engine.
class Config {
  const Config({
    required this.cacheProvider,
    this.httpProvider = Providers.freshHttpClient,
    required this.secretManager,
  });

  // List of environment variable keys related to the Github app authentication.
  static const String kGithubKey = 'AUTO_SUBMIT_GITHUB_KEY';
  static const String kGithubAppId = 'AUTO_SUBMIT_GITHUB_APP_ID';

  final CacheProvider cacheProvider;
  final HttpProvider httpProvider;
  final SecretManager secretManager;

  Cache get cache => Cache(cacheProvider).withPrefix('config');

  Future<GithubService> createGithubService() async {
    final GitHub github = await createGithubClient();
    return GithubService(github);
  }

  Future<GitHub> createGithubClient() async {
    String token = await generateGithubToken();
    return GitHub(auth: Authentication.withToken(token));
  }

  Future<String> generateGithubToken() async {
    // GitHub's secondary rate limits are run into very frequently when making auth tokens.
    final Uint8List? cacheValue = await cache['githubToken'].get(
      _generateGithubToken,
      // Tokens have a TTL of 10 minutes. AppEngine requests have a TTL of 1 minute.
      // To ensure no expired tokens are used, set this to 10 - 1, with an extra buffer of a duplicate request.
      const Duration(minutes: 8),
    );
    return String.fromCharCodes(cacheValue!);
  }

  Future<String> getInstallationId() async {
    final String jwt = await _generateGithubJwt();
    final Map<String, String> headers = <String, String>{
      'Authorization': 'Bearer $jwt',
      'Accept': 'application/vnd.github.machine-man-preview+json'
    };
    // TODO(KristinBi): Upstream the github package.https://github.com/flutter/flutter/issues/100920
    final Uri githubInstallationUri = Uri.https('api.github.com', 'app/installations');
    final http.Client client = httpProvider();
    // TODO(KristinBi): Track the installation id by repo. https://github.com/flutter/flutter/issues/100808
    final http.Response response = await client.get(
      githubInstallationUri,
      headers: headers,
    );
    final list = json.decode(response.body).map((data) => (data) as Map<String, dynamic>).toList();
    final String installatinId = list[0]['id'].toString();
    return installatinId;
  }

  Future<GraphQLClient> createGitHubGraphQLClient() async {
    final HttpLink httpLink = HttpLink(
      'https://api.github.com/graphql',
      defaultHeaders: <String, String>{
        'Accept': 'application/vnd.github.antiope-preview+json',
      },
    );

    String token = await generateGithubToken();

    final AuthLink _authLink = AuthLink(
      getToken: () async => 'Bearer $token',
    );

    return GraphQLClient(
      cache: GraphQLCache(),
      link: _authLink.concat(httpLink),
    );
  }

  Future<Uint8List> _generateGithubToken() async {
    final String jwt = await _generateGithubJwt();
    final Map<String, String> headers = <String, String>{
      'Authorization': 'Bearer $jwt',
      'Accept': 'application/vnd.github.machine-man-preview+json'
    };
    final String installationId = await getInstallationId();
    final Uri githubAccessTokensUri = Uri.https('api.github.com', 'app/installations/$installationId/access_tokens');
    final http.Client client = httpProvider();
    final http.Response response = await client.post(
      githubAccessTokensUri,
      headers: headers,
    );
    final Map<String, dynamic> jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
    if (jsonBody.containsKey('token') == false) {
      log.warning(response.body);
      throw Exception('generateGithubToken failed to get token from Github');
    }
    final String token = jsonBody['token'] as String;
    return Uint8List.fromList(token.codeUnits);
  }

  Future<String> _generateGithubJwt() async {
    final String rawKey = await secretManager.get(kGithubKey);
    StringBuffer sb = StringBuffer();
    sb.writeln(rawKey.substring(0, 32));
    sb.writeln(rawKey.substring(32, rawKey.length - 30).replaceAll(' ', '  \n'));
    sb.writeln(rawKey.substring(rawKey.length - 30, rawKey.length));
    final String privateKey = sb.toString();

    final JWTBuilder builder = JWTBuilder();
    final DateTime now = DateTime.now();
    builder
      ..issuer = await secretManager.get(kGithubAppId)
      ..issuedAt = now
      ..expiresAt = now.add(const Duration(minutes: 10));
    final JWTRsaSha256Signer signer = JWTRsaSha256Signer(privateKey: privateKey);
    final JWT signedToken = builder.getSignedToken(signer);
    return signedToken.toString();
  }

  /// GitHub repositories that use CI status to determine if pull requests can be submitted.
  static Set<RepositorySlug> reposWithTreeStatus = <RepositorySlug>{
    engineSlug,
    flutterSlug,
  };

  static RepositorySlug get engineSlug => RepositorySlug('flutter', 'engine');
  static RepositorySlug get flutterSlug => RepositorySlug('flutter', 'flutter');

  /// The names of autoroller accounts for the repositories.
  ///
  /// These accounts should not need reviews before merging. See
  /// https://github.com/flutter/flutter/wiki/Autorollers
  Set<String> get rollerAccounts => const <String>{
        'skia-flutter-autoroll',
        'engine-flutter-autoroll',
        'dependabot',
      };

  /// The label which shows the overrideTreeStatus.
  String get overrideTreeStatusLabel => 'warning: land on red to fix tree breakage';

  /// The autosubmit label.
  String get autosubmitLabel => 'autosubmit';
}

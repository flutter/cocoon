// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:corsac_jwt/corsac_jwt.dart';
import 'package:github/github.dart';
import 'package:http/http.dart' as http;
import 'package:neat_cache/cache_provider.dart';
import 'package:neat_cache/neat_cache.dart';

import '../foundation/providers.dart';
import 'github_service.dart';
import 'log.dart';

/// Configuration for the autosubmit engine.
class Config {
  const Config({
    required this.cacheProvider,
    this.httpProvider = Providers.freshHttpClient,
  });

  // List of environment variable keys related to the Github app authentication.
  static const String kGithubKey = 'GITHUB_KEY';
  static const String kGithubAppId = 'GITHUB_APP_ID';

  final CacheProvider cacheProvider;
  final HttpProvider httpProvider;

  Cache get cache => Cache(cacheProvider).withPrefix('config').withCodec(utf8);

  Future<GithubService> createGithubService() async {
    final GitHub github = await createGithubClient();
    return GithubService(github);
  }

  Future<GitHub> createGithubClient() async {
    // GitHub's secondary rate limits are run into very frequently when making auth tokens.
    final String token = await cache['githubToken'].get(
      _generateGithubToken,
      // Tokens have a TTL of 10 minutes. AppEngine requests have a TTL of 1 minute.
      // To ensure no expired tokens are used, set this to 10 - 1, with an extra buffer of a duplicate request.
      const Duration(minutes: 8),
    );

    return GitHub(auth: Authentication.withToken(token));
  }

  Future<Uint8List> _generateGithubToken() async {
    final String jwt = await _generateGithubJwt();
    final Map<String, String> headers = <String, String>{
      'Authorization': 'Bearer $jwt',
      'Accept': 'application/vnd.github.machine-man-preview+json'
    };
    final Uri githubAccessTokensUri =
        Uri.https('api.github.com', 'app/installations/${_getFromEnv(kGithubAppId)}/access_tokens');
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
    final String privateKey = _getFromEnv(kGithubKey);
    final JWTBuilder builder = JWTBuilder();
    final DateTime now = DateTime.now();
    builder
      ..issuer = _getFromEnv(kGithubAppId)
      ..issuedAt = now
      ..expiresAt = now.add(const Duration(minutes: 10));
    final JWTRsaSha256Signer signer = JWTRsaSha256Signer(privateKey: privateKey);
    final JWT signedToken = builder.getSignedToken(signer);
    return signedToken.toString();
  }

  String _getFromEnv(String key) {
    String? value = Platform.environment[key];
    if (value == null) {
      throw Exception(
          'Failed to find $key in environment variable. The server will need to set it and be re-deployed.');
    }

    return value;
  }
}

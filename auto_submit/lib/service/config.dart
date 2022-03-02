// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/requests/cirrus_graphql_client.dart';
import 'package:graphql/client.dart';
import 'package:github/github.dart';

import 'github_service.dart';

/// Represents the whole config for the autosubmit engine.
class Config {
  const Config();

  GitHub createGitHubClientWithToken(String token) {
    return GitHub(auth: Authentication.withToken(token));
  }

  GithubService createGithubServiceWithToken(String token) {
    final GitHub github = createGitHubClientWithToken(token);
    return GithubService(github);
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

  Future<CirrusGraphQLClient> createCirrusGraphQLClient() async {
    final HttpLink httpLink = HttpLink(
      'https://api.cirrus-ci.com/graphql',
    );

    return CirrusGraphQLClient(
      cache: GraphQLCache(),
      link: httpLink,
    );
  }

  String get overrideTreeStatusLabel => 'warning: land on red to fix tree breakage';
}

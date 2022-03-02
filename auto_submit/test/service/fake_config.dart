// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:auto_submit/service/config.dart';
import 'package:auto_submit/service/github_service.dart';
import 'package:auto_submit/requests/cirrus_graphql_client.dart';
import 'package:github/github.dart';

// ignore: must_be_immutable
class FakeConfig implements Config {
  FakeConfig({
    this.githubClient,
    this.githubService,
    this.cirrusGraphQLClient,
    this.rollerAccountsValue,
  });

  GitHub? githubClient;
  GithubService? githubService;
  CirrusGraphQLClient? cirrusGraphQLClient;
  Set<String>? rollerAccountsValue;
  String? overrideTreeStatusLabelValue;

  @override
  GitHub createGitHubClientWithToken(String token) => githubClient!;

  @override
  GithubService createGithubServiceWithToken(String token) => githubService!;

  @override
  Future<CirrusGraphQLClient> createCirrusGraphQLClient() async =>
      cirrusGraphQLClient!;

  @override
  Set<String> get rollerAccounts => rollerAccountsValue!;

  @override
  String get overrideTreeStatusLabel => overrideTreeStatusLabelValue!;
}

// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:auto_submit/configuration/repository_configuration.dart';
import 'package:auto_submit/service/config.dart';
import 'package:auto_submit/service/github_service.dart';
import 'package:auto_submit/service/secrets.dart';
import 'package:cocoon_server/bigquery.dart';
import 'package:github/github.dart';
import 'package:graphql/client.dart';
import 'package:neat_cache/neat_cache.dart';

import 'fake_github_service.dart';

// Represents a fake config to be used in unit test.
class FakeConfig extends Config {
  FakeConfig({
    this.githubClient,
    this.githubGraphQLClient,
    this.githubService,
    this.rollerAccountsValue,
    this.webhookKey,
    this.kPubsubPullNumberValue,
    this.bigqueryService,
  }) : super(
         cacheProvider: Cache.inMemoryCacheProvider(4),
         secretManager: LocalSecretManager(),
       );

  GitHub? githubClient;
  GraphQLClient? githubGraphQLClient;
  GithubService? githubService = FakeGithubService();
  Set<String>? rollerAccountsValue;
  String? webhookKey;
  int? kPubsubPullNumberValue;
  BigqueryService? bigqueryService;
  RepositoryConfiguration? repositoryConfigurationMock;

  @override
  String get pubsubPullRequestTopic => 'auto-submit-queue';
  @override
  String get pubsubPullRequestSubscription => 'auto-submit-queue-sub';
  @override
  String get pubsubRevertRequestTopic => 'auto-submit-revert-queue';
  @override
  String get pubsubRevertRequestSubscription => 'auto-submit-revert-queue-sub';

  @override
  int get kPubsubPullNumber => kPubsubPullNumberValue ?? 1;

  @override
  Future<GitHub> createGithubClient(RepositorySlug slug) async => githubClient!;

  @override
  Future<GitHub> createFlutterGitHubBotClient(RepositorySlug slug) async =>
      githubClient!;

  @override
  Future<GithubService> createGithubService(RepositorySlug slug) async =>
      githubService ?? FakeGithubService();

  @override
  Future<GraphQLClient> createGitHubGraphQLClient(RepositorySlug slug) async =>
      githubGraphQLClient!;

  @override
  Set<String> get rollerAccounts =>
      rollerAccountsValue ??
      const <String>{
        'skia-flutter-autoroll',
        'engine-flutter-autoroll',
        'dependabot[bot]',
        'dependabot',
      };

  @override
  Future<String> getWebhookKey() async {
    return webhookKey ?? 'not_a_real_key';
  }

  @override
  Future<String> getFlutterGitHubBotToken() async {
    return 'not_a_real_token';
  }

  @override
  Future<String> getTreeStatusDiscordUrl() async => 'discord.com';

  @override
  Future<BigqueryService> createBigQueryService() async => bigqueryService!;

  @override
  Future<RepositoryConfiguration> getRepositoryConfiguration(
    RepositorySlug slug,
  ) async => repositoryConfigurationMock!;
}

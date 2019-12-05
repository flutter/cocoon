// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:appengine/appengine.dart';
import 'package:cocoon_service/src/datastore/cocoon_config.dart';
import 'package:cocoon_service/src/model/appengine/service_account_info.dart';
import 'package:cocoon_service/src/service/github_service.dart';
import 'package:github/server.dart';
import 'package:graphql/client.dart';
import 'package:googleapis/bigquery/v2.dart';

import 'fake_datastore.dart';

// ignore: must_be_immutable
class FakeConfig implements Config {
  FakeConfig({
    this.maxEntityGroups = 5,
    this.githubClient,
    this.deviceLabServiceAccountValue,
    this.forwardHostValue,
    this.forwardPortValue,
    this.forwardSchemeValue,
    this.maxTaskRetriesValue,
    this.oauthClientIdValue,
    this.githubOAuthTokenValue,
    this.missingTestsPullRequestMessageValue,
    this.nonMasterPullRequestMessageValue,
    this.goldenBreakingChangeMessageValue,
    this.goldenTriageMessageValue,
    this.webhookKeyValue,
    this.cqLabelNameValue,
    this.luciBuildersValue,
    this.luciTryBuildersValue,
    this.loggingServiceValue,
    this.redisUrlValue,
    this.redisResponseSubcacheValue,
    this.tabledataResourceApi,
    this.githubService,
    FakeDatastoreDB dbValue,
  }) : dbValue = dbValue ?? FakeDatastoreDB();

  GitHub githubClient;
  GraphQLClient githubGraphQLClient;
  TabledataResourceApi tabledataResourceApi;
  GithubService githubService;
  FakeDatastoreDB dbValue;
  ServiceAccountInfo deviceLabServiceAccountValue;
  String forwardHostValue;
  int forwardPortValue;
  String forwardSchemeValue;
  int maxTaskRetriesValue;
  String oauthClientIdValue;
  String githubOAuthTokenValue;
  String missingTestsPullRequestMessageValue;
  String nonMasterPullRequestMessageValue;
  String goldenBreakingChangeMessageValue;
  String goldenTriageMessageValue;
  String webhookKeyValue;
  String cqLabelNameValue;
  List<Map<String, dynamic>> luciBuildersValue;
  List<Map<String, dynamic>> luciTryBuildersValue;
  Logging loggingServiceValue;
  String redisUrlValue;
  String redisResponseSubcacheValue;
  String waitingForTreeToGoGreenLabelNameValue;

  @override
  int maxEntityGroups;

  @override
  Future<GitHub> createGitHubClient() async => githubClient;

  @override
  Future<GraphQLClient> createGitHubGraphQLClient() async => githubGraphQLClient;

  @override
  Future<TabledataResourceApi> createTabledataResourceApi() async => tabledataResourceApi;

  @override
  Future<GithubService> createGithubService() async => githubService;

  @override
  FakeDatastoreDB get db => dbValue;

  @override
  Future<ServiceAccountInfo> get deviceLabServiceAccount async => deviceLabServiceAccountValue;

  @override
  Future<String> get forwardHost async => forwardHostValue;

  @override
  Future<int> get forwardPort async => forwardPortValue;

  @override
  Future<String> get forwardScheme async => forwardSchemeValue;

  @override
  Future<int> get maxTaskRetries async => maxTaskRetriesValue;

  @override
  Future<String> get oauthClientId async => oauthClientIdValue;

  @override
  Future<String> get githubOAuthToken async => githubOAuthTokenValue;

  @override
  Future<String> get missingTestsPullRequestMessage async => missingTestsPullRequestMessageValue;

  @override
  Future<String> get nonMasterPullRequestMessage async => nonMasterPullRequestMessageValue;

  @override
  Future<String> get goldenBreakingChangeMessage async => goldenBreakingChangeMessageValue;

  @override
  Future<String> get goldenTriageMessage async => goldenTriageMessageValue;

  @override
  Future<String> get webhookKey async => webhookKeyValue;

  @override
  Future<String> get cqLabelName async => cqLabelNameValue;

  @override
  Future<List<Map<String, dynamic>>> get luciBuilders async => luciBuildersValue;

  @override
  Future<List<Map<String, dynamic>>> get luciTryBuilders async => luciTryBuildersValue;

  @override
  Logging get loggingService => loggingServiceValue;

  @override
  Future<String> get redisUrl async => redisUrlValue;

  @override
  Future<String> get redisResponseSubcache async => redisResponseSubcacheValue;

  @override
  Future<String> get waitingForTreeToGoGreenLabelName async =>
      waitingForTreeToGoGreenLabelNameValue;
}

// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:appengine/appengine.dart';
import 'package:cocoon_service/src/datastore/cocoon_config.dart';
import 'package:cocoon_service/src/model/appengine/service_account_info.dart';
import 'package:cocoon_service/src/service/github_service.dart';
import 'package:github/server.dart';
import 'package:googleapis_auth/auth.dart';
import 'package:graphql/client.dart';
import 'package:googleapis/bigquery/v2.dart';

import 'fake_datastore.dart';

// ignore: must_be_immutable
class FakeConfig implements Config {
  FakeConfig({
    this.maxEntityGroups = 5,
    this.githubClient,
    this.deviceLabServiceAccountValue,
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
    this.tabledataResourceApi,
    this.githubService,
    this.taskLogServiceAccountValue,
    FakeDatastoreDB dbValue,
  }) : dbValue = dbValue ?? FakeDatastoreDB();

  GitHub githubClient;
  GraphQLClient githubGraphQLClient;
  TabledataResourceApi tabledataResourceApi;
  GithubService githubService;
  FakeDatastoreDB dbValue;
  ServiceAccountInfo deviceLabServiceAccountValue;
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
  String waitingForTreeToGoGreenLabelNameValue;
  ServiceAccountCredentials taskLogServiceAccountValue;

  @override
  int maxEntityGroups;

  @override
  Future<GitHub> createGitHubClient(String repo) async => githubClient;

  @override
  Future<GraphQLClient> createGitHubGraphQLClient(String repo) async =>
      githubGraphQLClient;

  @override
  Future<TabledataResourceApi> createTabledataResourceApi() async =>
      tabledataResourceApi;

  @override
  Future<GithubService> createGithubService(String repo) async => githubService;

  @override
  FakeDatastoreDB get db => dbValue;

  @override
  Future<ServiceAccountInfo> get deviceLabServiceAccount async =>
      deviceLabServiceAccountValue;

  @override
  int get maxTaskRetries => maxTaskRetriesValue;

  @override
  Future<String> get oauthClientId async => oauthClientIdValue;

  @override
  Future<String> githubOAuthToken(String repo) async => githubOAuthTokenValue;

  @override
  String get missingTestsPullRequestMessage =>
      missingTestsPullRequestMessageValue;

  @override
  String get nonMasterPullRequestMessage => nonMasterPullRequestMessageValue;

  @override
  String get goldenBreakingChangeMessage => goldenBreakingChangeMessageValue;

  @override
  String get goldenTriageMessage => goldenTriageMessageValue;

  @override
  Future<String> get webhookKey async => webhookKeyValue;

  @override
  String get cqLabelName => cqLabelNameValue;

  @override
  List<Map<String, dynamic>> get luciBuilders => luciBuildersValue;

  @override
  List<Map<String, dynamic>> get luciTryBuilders => luciTryBuildersValue;

  @override
  Logging get loggingService => loggingServiceValue;

  @override
  String get waitingForTreeToGoGreenLabelName =>
      waitingForTreeToGoGreenLabelNameValue;

  @override
  Future<ServiceAccountCredentials> get taskLogServiceAccount async =>
      taskLogServiceAccountValue;
}

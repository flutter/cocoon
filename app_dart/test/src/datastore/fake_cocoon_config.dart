// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:appengine/appengine.dart';
import 'package:cocoon_service/src/datastore/cocoon_config.dart';
import 'package:cocoon_service/src/model/appengine/key_helper.dart';
import 'package:cocoon_service/src/model/appengine/service_account_info.dart';
import 'package:cocoon_service/src/service/github_service.dart';
import 'package:github/github.dart';
import 'package:googleapis_auth/auth.dart';
import 'package:graphql/client.dart';
import 'package:googleapis/bigquery/v2.dart';
import '../request_handling/fake_authentication.dart';
import 'fake_datastore.dart';

// ignore: must_be_immutable
class FakeConfig implements Config {
  FakeConfig({
    this.githubClient,
    this.deviceLabServiceAccountValue,
    this.maxTaskRetriesValue,
    this.commitNumberValue,
    this.existingBranchHoursValue,
    this.newBranchHoursValue,
    this.keyHelperValue,
    this.oauthClientIdValue,
    this.githubOAuthTokenValue,
    this.missingTestsPullRequestMessageValue,
    this.nonMasterPullRequestMessageValue,
    this.goldenBreakingChangeMessageValue,
    this.goldenTriageMessageValue,
    this.goldenBranchMessageValue,
    this.webhookKeyValue,
    this.cqLabelNameValue,
    this.luciBuildersValue,
    this.luciTryBuildersValue,
    this.loggingServiceValue,
    this.tabledataResourceApi,
    this.githubService,
    this.cirrusGraphQLClient,
    this.taskLogServiceAccountValue,
    this.rollerAccountsValue,
    this.luciTryInfraFailureRetriesValue,
    this.flutterSlugValue,
    this.flutterBuildValue,
    this.flutterBuildDescriptionValue,
    this.flutterBranchesValue,
    this.maxRecordsValue,
    this.defaultBranchValue,
    FakeDatastoreDB dbValue,
  }) : dbValue = dbValue ?? FakeDatastoreDB();

  GitHub githubClient;
  GraphQLClient githubGraphQLClient;
  GraphQLClient cirrusGraphQLClient;
  TabledataResourceApi tabledataResourceApi;
  GithubService githubService;
  FakeDatastoreDB dbValue;
  ServiceAccountInfo deviceLabServiceAccountValue;
  int maxTaskRetriesValue;
  int commitNumberValue;
  int existingBranchHoursValue;
  int newBranchHoursValue;
  FakeKeyHelper keyHelperValue;
  String oauthClientIdValue;
  String githubOAuthTokenValue;
  String missingTestsPullRequestMessageValue;
  String nonMasterPullRequestMessageValue;
  String goldenBreakingChangeMessageValue;
  String goldenTriageMessageValue;
  String goldenBranchMessageValue;
  String webhookKeyValue;
  String cqLabelNameValue;
  String flutterBuildValue;
  String flutterBuildDescriptionValue;
  List<Map<String, dynamic>> luciBuildersValue;
  List<Map<String, dynamic>> luciTryBuildersValue;
  Logging loggingServiceValue;
  String waitingForTreeToGoGreenLabelNameValue;
  ServiceAccountCredentials taskLogServiceAccountValue;
  Set<String> rollerAccountsValue;
  int luciTryInfraFailureRetriesValue;
  RepositorySlug flutterSlugValue;
  List<String> flutterBranchesValue;
  int maxRecordsValue;
  String defaultBranchValue;

  @override
  int get luciTryInfraFailureRetries => luciTryInfraFailureRetriesValue;

  @override
  Future<GitHub> createGitHubClient() async => githubClient;

  @override
  Future<GraphQLClient> createGitHubGraphQLClient() async =>
      githubGraphQLClient;

  @override
  Future<GraphQLClient> createCirrusGraphQLClient() async =>
      cirrusGraphQLClient;

  @override
  Future<TabledataResourceApi> createTabledataResourceApi() async =>
      tabledataResourceApi;

  @override
  Future<GithubService> createGithubService() async => githubService;

  @override
  FakeDatastoreDB get db => dbValue;

  @override
  String get defaultBranch => defaultBranchValue;

  @override
  Future<ServiceAccountInfo> get deviceLabServiceAccount async =>
      deviceLabServiceAccountValue;

  @override
  int get maxTaskRetries => maxTaskRetriesValue;

  @override
  int get maxRecords => maxRecordsValue;

  @override
  int get commitNumber => commitNumberValue;

  @override
  int get existingBranchHours => existingBranchHoursValue;

  @override
  int get newBranchHours => newBranchHoursValue;

  @override
  Future<List<String>> get flutterBranches async => flutterBranchesValue;

  @override
  KeyHelper get keyHelper => keyHelperValue;

  @override
  Future<String> get oauthClientId async => oauthClientIdValue;

  @override
  Future<String> get githubOAuthToken async => githubOAuthTokenValue;

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
  String get goldenBranchMessage => goldenBranchMessageValue;

  @override
  Future<String> get webhookKey async => webhookKeyValue;

  @override
  String get cqLabelName => cqLabelNameValue;

  @override
  String get flutterBuild => flutterBuildValue;

  @override
  String get flutterBuildDescription => flutterBuildDescriptionValue;

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
  RepositorySlug get flutterSlug => flutterSlugValue;

  @override
  Future<ServiceAccountCredentials> get taskLogServiceAccount async =>
      taskLogServiceAccountValue;

  @override
  Set<String> get rollerAccounts => rollerAccountsValue;

  @override
  bool githubPresubmitSupportedRepo(String repositoryName) {
    return <String>['flutter', 'engine', 'cocoon'].contains(repositoryName);
  }
}

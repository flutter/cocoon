// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:appengine/appengine.dart';
import 'package:github/github.dart';
import 'package:googleapis_auth/auth.dart';
import 'package:graphql/client.dart';
import 'package:googleapis/bigquery/v2.dart';

import 'package:cocoon_service/src/datastore/config.dart';
import 'package:cocoon_service/src/model/appengine/key_helper.dart';
import 'package:cocoon_service/src/model/appengine/service_account_info.dart';
import 'package:cocoon_service/src/service/github_service.dart';
import 'package:cocoon_service/src/service/luci.dart';
import 'package:metrics_center/src/flutter.dart';

import '../request_handling/fake_authentication.dart';
import 'fake_datastore.dart';

// ignore: must_be_immutable
class FakeConfig implements Config {
  FakeConfig({
    this.githubClient,
    this.deviceLabServiceAccountValue,
    this.maxTaskRetriesValue,
    this.maxLuciTaskRetriesValue,
    this.commitNumberValue,
    this.keyHelperValue,
    this.oauthClientIdValue,
    this.githubOAuthTokenValue,
    this.mergeConflictPullRequestMessageValue = 'default mergeConflictPullRequestMessageValue',
    this.missingTestsPullRequestMessageValue = 'default missingTestsPullRequestMessageValue',
    this.wrongBaseBranchPullRequestMessageValue,
    this.wrongHeadBranchPullRequestMessageValue,
    this.releaseBranchPullRequestMessageValue,
    this.webhookKeyValue,
    this.loggingServiceValue,
    this.tabledataResourceApi,
    this.githubService,
    this.githubGraphQLClient,
    this.cirrusGraphQLClient,
    this.metricsDestination,
    this.taskLogServiceAccountValue,
    this.rollerAccountsValue,
    this.flutterSlugValue,
    this.flutterBuildValue,
    this.flutterBuildDescriptionValue,
    this.flutterBranchesValue,
    this.maxRecordsValue,
    this.flutterGoldPendingValue,
    this.flutterGoldSuccessValue,
    this.flutterGoldChangesValue,
    this.flutterGoldAlertConstantValue,
    this.flutterGoldInitialAlertValue,
    this.flutterGoldFollowUpAlertValue,
    this.flutterGoldDraftChangeValue,
    this.flutterGoldStalePRValue,
    FakeDatastoreDB dbValue,
  }) : dbValue = dbValue ?? FakeDatastoreDB();

  GitHub githubClient;
  GraphQLClient githubGraphQLClient;
  GraphQLClient cirrusGraphQLClient;
  TabledataResourceApi tabledataResourceApi;
  GithubService githubService;
  FlutterDestination metricsDestination;
  FakeDatastoreDB dbValue;
  ServiceAccountInfo deviceLabServiceAccountValue;
  int maxTaskRetriesValue;
  int maxLuciTaskRetriesValue;
  int commitNumberValue;
  FakeKeyHelper keyHelperValue;
  String oauthClientIdValue;
  String githubOAuthTokenValue;
  String mergeConflictPullRequestMessageValue;
  String missingTestsPullRequestMessageValue;
  String wrongBaseBranchPullRequestMessageValue;
  String wrongHeadBranchPullRequestMessageValue;
  String releaseBranchPullRequestMessageValue;
  String webhookKeyValue;
  String flutterBuildValue;
  String flutterBuildDescriptionValue;
  Logging loggingServiceValue;
  String waitingForTreeToGoGreenLabelNameValue;
  ServiceAccountCredentials taskLogServiceAccountValue;
  Set<String> rollerAccountsValue;
  RepositorySlug flutterSlugValue;
  List<String> flutterBranchesValue;
  int maxRecordsValue;
  String flutterGoldPendingValue;
  String flutterGoldSuccessValue;
  String flutterGoldChangesValue;
  String flutterGoldAlertConstantValue;
  String flutterGoldInitialAlertValue;
  String flutterGoldFollowUpAlertValue;
  String flutterGoldDraftChangeValue;
  String flutterGoldStalePRValue;

  @override
  Future<GitHub> createGitHubClient(String owner, String repository) async => githubClient;

  @override
  Future<GraphQLClient> createGitHubGraphQLClient() async => githubGraphQLClient;

  @override
  Future<GraphQLClient> createCirrusGraphQLClient() async => cirrusGraphQLClient;

  @override
  Future<TabledataResourceApi> createTabledataResourceApi() async => tabledataResourceApi;

  @override
  Future<GithubService> createGithubService(String owner, String repository) async => githubService;

  @override
  Future<FlutterDestination> createMetricsDestination() async => metricsDestination;

  @override
  FakeDatastoreDB get db => dbValue;

  @override
  String get defaultBranch => kDefaultBranchName;

  @override
  Future<ServiceAccountInfo> get deviceLabServiceAccount async => deviceLabServiceAccountValue;

  @override
  int get maxTaskRetries => maxTaskRetriesValue;

  @override
  int get maxLuciTaskRetries => maxLuciTaskRetriesValue;

  @override
  int get maxRecords => maxRecordsValue;

  @override
  String get flutterGoldPending => flutterGoldPendingValue;

  @override
  String get flutterGoldSuccess => flutterGoldSuccessValue;

  @override
  String get flutterGoldChanges => flutterGoldChangesValue;

  @override
  String get flutterGoldDraftChange => flutterGoldDraftChangeValue;

  @override
  String get flutterGoldStalePR => flutterGoldStalePRValue;

  @override
  String flutterGoldInitialAlert(String url) => flutterGoldInitialAlertValue;

  @override
  String flutterGoldFollowUpAlert(String url) => flutterGoldFollowUpAlertValue;

  @override
  String get flutterGoldAlertConstant => flutterGoldAlertConstantValue;

  @override
  String flutterGoldCommentID(PullRequest pr) => 'PR ${pr.number}, at ${pr.head.sha}';

  @override
  int get commitNumber => commitNumberValue;

  @override
  Future<List<String>> get flutterBranches async => flutterBranchesValue;

  @override
  KeyHelper get keyHelper => keyHelperValue;

  @override
  Future<String> get oauthClientId async => oauthClientIdValue;

  @override
  Future<String> get githubOAuthToken async => githubOAuthTokenValue;

  @override
  String get mergeConflictPullRequestMessage => mergeConflictPullRequestMessageValue;

  @override
  String get missingTestsPullRequestMessage => missingTestsPullRequestMessageValue;

  @override
  String get wrongBaseBranchPullRequestMessage => wrongBaseBranchPullRequestMessageValue;

  @override
  String wrongHeadBranchPullRequestMessage(String branch) => wrongHeadBranchPullRequestMessageValue;

  @override
  String get releaseBranchPullRequestMessage => releaseBranchPullRequestMessageValue;

  @override
  Future<String> get webhookKey async => webhookKeyValue;

  @override
  String get flutterBuild => flutterBuildValue;

  @override
  String get flutterBuildDescription => flutterBuildDescriptionValue;

  @override
  Logging get loggingService => loggingServiceValue;

  @override
  String get waitingForTreeToGoGreenLabelName => waitingForTreeToGoGreenLabelNameValue;

  @override
  RepositorySlug get flutterSlug => flutterSlugValue;

  @override
  Future<ServiceAccountCredentials> get taskLogServiceAccount async => taskLogServiceAccountValue;

  @override
  Set<String> get rollerAccounts => rollerAccountsValue;

  @override
  bool githubPresubmitSupportedRepo(String repositoryName) {
    return <String>['flutter', 'engine', 'cocoon', 'packages'].contains(repositoryName);
  }

  @override
  Future<String> generateGithubToken(String user, String repository) {
    throw UnimplementedError();
  }

  @override
  Future<String> generateJsonWebToken() {
    throw UnimplementedError();
  }

  @override
  Future<String> get githubAppId => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> get githubAppInstallations => throw UnimplementedError();

  @override
  Future<String> get githubPrivateKey => throw UnimplementedError();

  @override
  Future<String> get githubPublicKey => throw UnimplementedError();

  @override
  bool isChecksSupportedRepo(RepositorySlug slug) {
    return '${slug.owner}/${slug.name}' == 'flutter/cocoon';
  }

  @override
  Future<List<LuciBuilder>> luciBuilders(String bucket, String repo,
      {String commitSha = 'master', int prNumber}) async {
    if (repo == 'flutter') {
      return <LuciBuilder>[
        const LuciBuilder(name: 'Linux', repo: 'flutter', taskName: 'linux_bot', flaky: false),
        const LuciBuilder(name: 'Mac', repo: 'flutter', taskName: 'mac_bot', flaky: false),
        const LuciBuilder(name: 'Windows', repo: 'flutter', taskName: 'windows_bot', flaky: false),
        const LuciBuilder(name: 'Linux Coverage', repo: 'flutter', taskName: 'coverage_bot', flaky: true)
      ];
    } else if (repo == 'cocoon') {
      return <LuciBuilder>[const LuciBuilder(name: 'Cocoon', repo: 'cocoon', taskName: 'cocoon_bot', flaky: true)];
    } else if (repo == 'engine') {
      return <LuciBuilder>[const LuciBuilder(name: 'Linux', repo: 'engine', taskName: 'coverage_bot', flaky: true)];
    }
    return <LuciBuilder>[];
  }

  @override
  String get luciProdAccount => 'flutter-prod-builder@chops-service-accounts.iam.gserviceaccount.com';
}

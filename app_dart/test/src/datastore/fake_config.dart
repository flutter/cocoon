// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:appengine/appengine.dart';
import 'package:cocoon_service/src/model/appengine/key_helper.dart';
import 'package:cocoon_service/src/model/appengine/service_account_info.dart';
import 'package:cocoon_service/src/service/bigquery.dart';
import 'package:cocoon_service/src/service/config.dart';
import 'package:cocoon_service/src/service/github_service.dart';
import 'package:cocoon_service/src/service/luci.dart';
import 'package:github/github.dart';
import 'package:googleapis/bigquery/v2.dart';
import 'package:graphql/client.dart';

import '../request_handling/fake_authentication.dart';
import 'fake_datastore.dart';

// ignore: must_be_immutable
class FakeConfig implements Config {
  FakeConfig({
    this.githubClient,
    this.deviceLabServiceAccountValue,
    this.maxTaskRetriesValue,
    this.maxLuciTaskRetriesValue,
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
    this.tabledataResource,
    this.githubService,
    this.bigqueryService,
    this.githubGraphQLClient,
    this.cirrusGraphQLClient,
    this.rollerAccountsValue,
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
    this.supportedBranchesValue,
    this.luciBuildersValue,
    FakeDatastoreDB? dbValue,
  }) : dbValue = dbValue ?? FakeDatastoreDB();

  GitHub? githubClient;
  GraphQLClient? githubGraphQLClient;
  GraphQLClient? cirrusGraphQLClient;
  TabledataResource? tabledataResource;
  BigqueryService? bigqueryService;
  GithubService? githubService;
  FakeDatastoreDB dbValue;
  ServiceAccountInfo? deviceLabServiceAccountValue;
  int? maxTaskRetriesValue;
  int? maxLuciTaskRetriesValue;
  FakeKeyHelper? keyHelperValue;
  String? oauthClientIdValue;
  String? githubOAuthTokenValue;
  String mergeConflictPullRequestMessageValue;
  String missingTestsPullRequestMessageValue;
  String? wrongBaseBranchPullRequestMessageValue;
  String? wrongHeadBranchPullRequestMessageValue;
  String? releaseBranchPullRequestMessageValue;
  String? webhookKeyValue;
  String? flutterBuildValue;
  String? flutterBuildDescriptionValue;
  Logging? loggingServiceValue;
  String? waitingForTreeToGoGreenLabelNameValue;
  Set<String>? rollerAccountsValue;
  List<String>? flutterBranchesValue;
  int? maxRecordsValue;
  String? flutterGoldPendingValue;
  String? flutterGoldSuccessValue;
  String? flutterGoldChangesValue;
  String? flutterGoldAlertConstantValue;
  String? flutterGoldInitialAlertValue;
  String? flutterGoldFollowUpAlertValue;
  String? flutterGoldDraftChangeValue;
  String? flutterGoldStalePRValue;
  List<String>? supportedBranchesValue;
  List<LuciBuilder>? luciBuildersValue;
  String? overrideTreeStatusLabelValue;

  @override
  Future<GitHub> createGitHubClient({PullRequest? pullRequest, RepositorySlug? slug}) async => githubClient!;

  @override
  GitHub createGitHubClientWithToken(String token) => githubClient!;

  @override
  Future<GraphQLClient> createGitHubGraphQLClient() async => githubGraphQLClient!;

  @override
  Future<GraphQLClient> createCirrusGraphQLClient() async => cirrusGraphQLClient!;

  @override
  Future<TabledataResource> createTabledataResourceApi() async => tabledataResource!;

  @override
  Future<BigqueryService> createBigQueryService() async => bigqueryService!;

  @override
  Future<GithubService> createGithubService(RepositorySlug slug) async => githubService!;

  @override
  GithubService createGithubServiceWithToken(String token) => githubService!;

  @override
  FakeDatastoreDB get db => dbValue;

  @override
  int get maxTaskRetries => maxTaskRetriesValue!;

  /// Size of the shards to send to buildBucket when scheduling builds.
  @override
  int get schedulingShardSize => 5;

  @override
  int get maxLuciTaskRetries => maxLuciTaskRetriesValue!;

  @override
  int get maxRecords => maxRecordsValue!;

  @override
  String get flutterGoldPending => flutterGoldPendingValue!;

  @override
  String get flutterGoldSuccess => flutterGoldSuccessValue!;

  @override
  String get flutterGoldChanges => flutterGoldChangesValue!;

  @override
  String get flutterGoldDraftChange => flutterGoldDraftChangeValue!;

  @override
  String get flutterGoldStalePR => flutterGoldStalePRValue!;

  @override
  String flutterGoldInitialAlert(String url) => flutterGoldInitialAlertValue!;

  @override
  String flutterGoldFollowUpAlert(String url) => flutterGoldFollowUpAlertValue!;

  @override
  String flutterGoldAlertConstant(RepositorySlug slug) => flutterGoldAlertConstantValue!;

  @override
  String flutterGoldCommentID(PullRequest pr) => 'PR ${pr.number}, at ${pr.head!.sha}';

  @override
  int get commitNumber => 30;

  @override
  Future<List<String>> get flutterBranches async => flutterBranchesValue!;

  @override
  KeyHelper get keyHelper => keyHelperValue!;

  @override
  Future<String> get oauthClientId async => oauthClientIdValue!;

  @override
  Future<String> get githubOAuthToken async => githubOAuthTokenValue ?? 'token';

  @override
  String get mergeConflictPullRequestMessage => mergeConflictPullRequestMessageValue;

  @override
  String get missingTestsPullRequestMessage => missingTestsPullRequestMessageValue;

  @override
  String get wrongBaseBranchPullRequestMessage => wrongBaseBranchPullRequestMessageValue!;

  @override
  String wrongHeadBranchPullRequestMessage(String branch) => wrongHeadBranchPullRequestMessageValue!;

  @override
  String get releaseBranchPullRequestMessage => releaseBranchPullRequestMessageValue!;

  @override
  Future<String> get webhookKey async => webhookKeyValue!;

  @override
  String get flutterBuild => flutterBuildValue!;

  @override
  String get flutterBuildDescription =>
      flutterBuildDescriptionValue ??
      'Tree is currently broken. Please do not merge this '
          'PR unless it contains a fix for the tree.';

  @override
  Logging get loggingService => loggingServiceValue!;

  @override
  String get waitingForTreeToGoGreenLabelName => waitingForTreeToGoGreenLabelNameValue!;

  @override
  Set<String> get rollerAccounts => rollerAccountsValue!;

  @override
  bool githubPresubmitSupportedRepo(RepositorySlug slug) {
    return <RepositorySlug>[
      RepositorySlug('flutter', 'flutter'),
      RepositorySlug('flutter', 'engine'),
      RepositorySlug('flutter', 'cocoon'),
      RepositorySlug('flutter', 'packages'),
      RepositorySlug('flutter', 'plugins'),
    ].contains(slug);
  }

  @override
  Future<String> generateGithubToken(RepositorySlug slug) {
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
  Future<List<String>> getSupportedBranches(RepositorySlug slug) async => supportedBranchesValue!;

  @override
  Future<GithubService> createDefaultGitHubService() async => githubService!;

  @override
  Future<String> get overrideTreeStatusLabel async => overrideTreeStatusLabelValue!;

  @override
  String get defaultRecipeBundleRef => 'refs/heads/main';

  @override
  Future<List<String>> get releaseAccounts async => <String>['dart-flutter-releaser'];
}

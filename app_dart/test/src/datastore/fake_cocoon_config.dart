// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

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
    this.keyHelperValue,
    this.oauthClientIdValue,
    this.githubOAuthTokenValue,
    this.missingTestsPullRequestMessageValue,
    this.wrongBaseBranchPullRequestMessageValue,
    this.wrongHeadBranchPullRequestMessageValue,
    this.releaseBranchPullRequestMessageValue,
    this.goldenBreakingChangeMessageValue,
    this.goldenTriageMessageValue,
    this.webhookKeyValue,
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
    this.metricsCenterServiceAccountValue,
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
  FakeKeyHelper keyHelperValue;
  String oauthClientIdValue;
  String githubOAuthTokenValue;
  String missingTestsPullRequestMessageValue;
  String wrongBaseBranchPullRequestMessageValue;
  String wrongHeadBranchPullRequestMessageValue;
  String releaseBranchPullRequestMessageValue;
  String goldenBreakingChangeMessageValue;
  String goldenTriageMessageValue;
  String webhookKeyValue;
  String flutterBuildValue;
  String flutterBuildDescriptionValue;
  Logging loggingServiceValue;
  String waitingForTreeToGoGreenLabelNameValue;
  ServiceAccountCredentials taskLogServiceAccountValue;
  Set<String> rollerAccountsValue;
  int luciTryInfraFailureRetriesValue;
  RepositorySlug flutterSlugValue;
  List<String> flutterBranchesValue;
  int maxRecordsValue;
  String defaultBranchValue;
  Map<String, dynamic> metricsCenterServiceAccountValue;

  @override
  int get luciTryInfraFailureRetries => luciTryInfraFailureRetriesValue;

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
  FakeDatastoreDB get db => dbValue;

  @override
  String get defaultBranch => kDefaultBranchName;

  @override
  Future<ServiceAccountInfo> get deviceLabServiceAccount async => deviceLabServiceAccountValue;

  @override
  int get maxTaskRetries => maxTaskRetriesValue;

  @override
  int get maxRecords => maxRecordsValue;

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
  String get missingTestsPullRequestMessage => missingTestsPullRequestMessageValue;

  @override
  String get wrongBaseBranchPullRequestMessage => wrongBaseBranchPullRequestMessageValue;

  @override
  String wrongHeadBranchPullRequestMessage(String branch) => wrongHeadBranchPullRequestMessageValue;

  @override
  String get releaseBranchPullRequestMessage => releaseBranchPullRequestMessageValue;

  @override
  String get goldenBreakingChangeMessage => goldenBreakingChangeMessageValue;

  @override
  String get goldenTriageMessage => goldenTriageMessageValue;

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
  Future<Map<String, dynamic>> get metricsCenterServiceAccountJson async =>
      metricsCenterServiceAccountValue;

  Future<List<Map<String, dynamic>>> getRepoLuciBuilders(String bucket, String repo) async {
    if (repo == 'flutter') {
      return (json.decode('''[
                  {"name": "Linux", "repo": "flutter" , "task_name": "linux_bot", "flaky": false},
                  {"name": "Mac", "repo": "flutter", "task_name": "mac_bot", "flaky": false},
                  {"name": "Windows", "repo": "flutter", "task_name": "windows_bot", "flaky": false},
                  {"name": "Linux Coverage", "repo": "flutter", "task_name": "coverage_bot", "flaky": true}
                  ]''') as List<dynamic>).cast<Map<String, dynamic>>();
    } else if (repo == 'cocoon') {
      return (json.decode('[{"name": "Cocoon", "repo": "cocoon", "task_name": "cocoon_bot", "flaky": true}]')
              as List<dynamic>)
          .cast<Map<String, dynamic>>();
    } else if (repo == 'engine') {
      return (json.decode('[{"name": "Linux", "repo": "$repo", "task_name": "coverage_bot", "flaky": true}]')
              as List<dynamic>)
          .cast<Map<String, dynamic>>();
    }
    return (json.decode('[]') as List<dynamic>).cast<Map<String, dynamic>>();
  }
}

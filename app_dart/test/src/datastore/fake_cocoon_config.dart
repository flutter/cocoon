// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:appengine/appengine.dart';
import 'package:cocoon_service/src/datastore/cocoon_config.dart';
import 'package:cocoon_service/src/model/appengine/service_account_info.dart';
import 'package:github/src/common.dart';

import 'fake_datastore.dart';

// ignore: must_be_immutable
class FakeConfig implements Config {
  FakeConfig({
    this.maxEntityGroups,
    this.githubClient,
    this.dbValue,
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
    this.webhookKeyValue,
    this.cqLabelNameValue,
    this.luciBuildersValue,
    this.luciTryBuildersValue,
    this.loggingServiceValue,
  }) {
    dbValue ??= FakeDatastoreDB();
  }

  GitHub githubClient;
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
  String webhookKeyValue;
  String cqLabelNameValue;
  List<Map<String, dynamic>> luciBuildersValue;
  List<Map<String, dynamic>> luciTryBuildersValue;
  Logging loggingServiceValue;

  @override
  int maxEntityGroups;

  @override
  Future<GitHub> createGitHubClient() async => githubClient;

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
  Future<String> get webhookKey async => webhookKeyValue;

  @override
  Future<String> get cqLabelName async => cqLabelNameValue;

  @override
  Future<List<Map<String, dynamic>>> get luciBuilders async => luciBuildersValue;

  @override
  Future<List<Map<String, dynamic>>> get luciTryBuilders async => luciTryBuildersValue;

  @override
  Logging get loggingService => loggingServiceValue;
}

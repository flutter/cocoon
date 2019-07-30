// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:cocoon_service/src/datastore/cocoon_config.dart';
import 'package:cocoon_service/src/model/appengine/service_account_info.dart';
import 'package:github/src/common.dart';

import 'fake_datastore.dart';

// ignore: must_be_immutable
class FakeConfig implements Config {
  FakeConfig({
    this.githubClient,
    this.dbValue,
    this.deviceLabServiceAccountValue,
    this.forwardHostValue,
    this.forwardPortValue,
    this.forwardSchemeValue,
    this.maxTaskRetriesValue,
    this.githubOAuthTokenValue,
    this.missingTestsPullRequestMessageValue,
    this.nonMasterPullRequestMessageValue,
    this.webhookKeyValue,
    this.luciBuildersValue,
  }) {
    dbValue ??= FakeDatastoreDB();
  }

  ServiceAccountInfo deviceLabServiceAccountValue;
  GitHub githubClient;
  FakeDatastoreDB dbValue;
  String forwardHostValue;
  int forwardPortValue;
  String forwardSchemeValue;
  int maxTaskRetriesValue;
  String githubOAuthTokenValue;
  String missingTestsPullRequestMessageValue;
  String nonMasterPullRequestMessageValue;
  String webhookKeyValue;
  List<Map<String, String>> luciBuildersValue;

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
  Future<String> get githubOAuthToken async => githubOAuthTokenValue;

  @override
  Future<String> get missingTestsPullRequestMessage async => missingTestsPullRequestMessageValue;

  @override
  Future<String> get nonMasterPullRequestMessage async => nonMasterPullRequestMessageValue;

  @override
  Future<String> get webhookKey async => webhookKeyValue;

  @override
  Future<String> get cqLabelName => throw UnimplementedError();

  @override
  Future<List<dynamic>> get luciBuilders async => luciBuildersValue;
}

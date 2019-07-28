// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:cocoon_service/src/datastore/cocoon_config.dart';
import 'package:gcloud/db.dart';
import 'package:github/src/common.dart';

// ignore: must_be_immutable
class FakeConfig implements Config {
  FakeConfig({
    this.deviceLabServiceAccountValue,
    this.forwardHostValue,
    this.forwardPortValue,
    this.forwardSchemeValue,
    this.githubOAuthTokenValue,
    this.missingTestsPullRequestMessageValue,
    this.nonMasterPullRequestMessageValue,
    this.webhookKeyValue,
  });

  Map<String, dynamic> deviceLabServiceAccountValue;
  String forwardHostValue;
  int forwardPortValue;
  String forwardSchemeValue;
  String githubOAuthTokenValue;
  String missingTestsPullRequestMessageValue;
  String nonMasterPullRequestMessageValue;
  String webhookKeyValue;

  @override
  Future<GitHub> createGitHubClient() => throw UnimplementedError();

  @override
  DatastoreDB get db => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> get deviceLabServiceAccount async => deviceLabServiceAccountValue;

  @override
  Future<String> get forwardHost async => forwardHostValue;

  @override
  Future<int> get forwardPort async => forwardPortValue;

  @override
  Future<String> get forwardScheme async => forwardSchemeValue;

  @override
  Future<String> get githubOAuthToken async => githubOAuthTokenValue;

  @override
  Future<String> get missingTestsPullRequestMessage async => missingTestsPullRequestMessageValue;

  @override
  Future<String> get nonMasterPullRequestMessage async => nonMasterPullRequestMessageValue;

  @override
  Future<String> get webhookKey async => webhookKeyValue;
}

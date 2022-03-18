// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:auto_submit/service/config.dart';
import 'package:auto_submit/service/github_service.dart';
import 'package:auto_submit/service/secrets.dart';
import 'package:github/github.dart';
import 'package:neat_cache/neat_cache.dart';

import 'fake_github_service.dart';

// Represents a fake config to be used in unit test.
class FakeConfig extends Config {
  FakeConfig({
    this.githubClient,
    this.githubService,
    this.rollerAccountsValue,
    this.overrideTreeStatusLabelValue,
    this.autosubmitLabelValue,
  }) : super(
          cacheProvider: Cache.inMemoryCacheProvider(4),
          secretManager: LocalSecretManager(),
        );

  GitHub? githubClient;
  GithubService? githubService = FakeGithubService();
  Set<String>? rollerAccountsValue;
  String? overrideTreeStatusLabelValue;
  String? autosubmitLabelValue;

  @override
  Future<GitHub> createGithubClient() async => githubClient!;

  @override
  Future<GithubService> createGithubService() async => githubService ?? FakeGithubService();

  @override
  Set<String> get rollerAccounts =>
      rollerAccountsValue ??
      const <String>{
        'skia-flutter-autoroll',
        'engine-flutter-autoroll',
        'dependabot',
      };

  @override
  String get overrideTreeStatusLabel => overrideTreeStatusLabelValue ?? 'warning: land on red to fix tree breakage';

  @override
  String get autosubmitLabel => autosubmitLabelValue ?? 'autosubmit';
}

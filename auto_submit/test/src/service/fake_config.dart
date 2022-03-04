// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:auto_submit/service/config.dart';
import 'package:auto_submit/service/github_service.dart';
import 'package:github/github.dart';
import 'package:neat_cache/neat_cache.dart';

// Represents a fake config to be used in unit test.
class FakeConfig extends Config {
  FakeConfig({
    this.githubClient,
    this.githubService,
  }) : super(cacheProvider: Cache.inMemoryCacheProvider(4));

  Future<GitHub>? githubClient;
  Future<GithubService>? githubService;

  @override
  Future<GitHub> createGithubClient() => githubClient!;

  @override
  Future<GithubService> createGithubService() => githubService!;
}

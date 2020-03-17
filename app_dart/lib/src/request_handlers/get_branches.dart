// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:github/server.dart';
import 'package:meta/meta.dart';

import '../datastore/cocoon_config.dart';
import '../foundation/providers.dart';
import '../foundation/typedefs.dart';
import '../foundation/utils.dart';
import '../request_handling/body.dart';
import '../request_handling/request_handler.dart';

/// Queries GitHub for the list of all available branches on
/// [config.flutterSlug] repo, and returns list of branches
/// that match pre-defined branch regular expressions.
@immutable
class GetBranches extends RequestHandler<Body> {
  const GetBranches(
    Config config, {
    @visibleForTesting
        this.branchHttpClientProvider = Providers.freshHttpClient,
    @visibleForTesting this.gitHubBackoffCalculator = twoSecondLinearBackoff,
  })  : assert(branchHttpClientProvider != null),
        assert(gitHubBackoffCalculator != null),
        super(config: config);

  final HttpClientProvider branchHttpClientProvider;
  final GitHubBackoffCalculator gitHubBackoffCalculator;

  @override
  Future<Body> get() async {
    final List<Branch> branchList = await getBranches(
        config, branchHttpClientProvider, log, gitHubBackoffCalculator);

    return Body.forJson(<String, List<String>>{
      'Branches': branchList.map((Branch branch) => branch.name).toList()
    });
  }
}

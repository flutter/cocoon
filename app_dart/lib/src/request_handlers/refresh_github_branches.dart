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
import '../request_handling/api_request_handler.dart';
import '../request_handling/authentication.dart';
import '../request_handling/body.dart';
import '../service/datastore.dart';

/// Queries GitHub for the list of available branches, fliters ones according 
/// to [branch_regexps], and updates [FlutterBranches] in datastore if values are
/// changed.
@immutable
class RefreshGithubBranches
    extends ApiRequestHandler<Body> {
  const RefreshGithubBranches(
    Config config,
    AuthenticationProvider authenticationProvider, {
    @visibleForTesting
        this.datastoreProvider = DatastoreService.defaultProvider,
    @visibleForTesting
        this.branchHttpClientProvider = Providers.freshHttpClient,
    @visibleForTesting this.gitHubBackoffCalculator = twoSecondLinearBackoff,
  })  : assert(datastoreProvider != null),
        assert(branchHttpClientProvider != null),
        assert(gitHubBackoffCalculator != null),
        super(config: config, authenticationProvider: authenticationProvider);

  final DatastoreServiceProvider datastoreProvider;
  final HttpClientProvider branchHttpClientProvider;
  final GitHubBackoffCalculator gitHubBackoffCalculator;

  @override
  Future<Body> get() async {
    final DatastoreService datastore = datastoreProvider(config.db);
    final List<Branch> branches = await getBranches(
        config, branchHttpClientProvider, log, gitHubBackoffCalculator);
    const String id = 'FlutterBranches';

    final CocoonConfig cocoonConfig = CocoonConfig()
      ..id = id
      ..parentKey = datastore.db.emptyKey;
    final CocoonConfig result =
        await datastore.db.lookupValue<CocoonConfig>(cocoonConfig.key);
    final String newValue =
        branches.map((Branch branch) => branch.name).toList().join(',');

    if (result.value != newValue) {
      result.value = newValue;
      await datastore.db.commit(inserts: <CocoonConfig>[result]);
    }

    return Body.empty;
  }
}

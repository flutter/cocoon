// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:cocoon_service/src/model/appengine/branch.dart';
import 'package:process_runner/process_runner.dart';

import '../../cocoon_service.dart';
import '../service/datastore.dart';

/// Return currently active branches across all repos.
///
/// Returns all branches with associated key, branch name and repository name, for branches with recent commit acitivies
/// within the past [GetBranches.kActiveBranchActivityPeriod] days.
///
/// GET: /api/public/get-branches
///
///
/// Response: Status 200 OK
///[
///      {
///         "key":ahFmbHV0dGVyLWRhc2hib2FyZHIuCxIGQnJhbmNoIiJmbHV0dGVyL2ZsdXR0ZXIvYnJhbmNoLWNyZWF0ZWQtb2xkDKIBCVtkZWZhdWx0XQ,
///         "branch":{
///            "branch":"branch-created-old",
///            "repository":"flutter/flutter"
///         }
///      }
///     {
///        "key":ahFmbHV0dGVyLWRhc2hib2FyZHIuCxIGQnJhbmNoIiJmbHV0dGVyL2ZsdXR0ZXIvYnJhbmNoLWNyZWF0ZWQtbm93DKIBCVtkZWZhdWx0XQ,
///        "branch":{
///           "branch":"branch-created-now",
///           "repository":"flutter/flutter"
///        }
///     }
///]

class GetBranches extends RequestHandler<Body> {
  GetBranches({
    required super.config,
    this.datastoreProvider = DatastoreService.defaultProvider,
    this.processRunner,
  });

  final DatastoreServiceProvider datastoreProvider;
  ProcessRunner? processRunner;

  static const Duration kActiveBranchActivity = Duration(days: 60);

  @override
  Future<Body> get() async {
    final DatastoreService datastore = datastoreProvider(config.db);

    List<Branch> branches = await datastore
        .queryBranches()
        .where(
          (Branch b) =>
              DateTime.now().millisecondsSinceEpoch - b.lastActivity! < kActiveBranchActivity.inMilliseconds ||
              <String>['main', 'master'].contains(b.name),
        )
        .toList();
    // From the dashboard point of view, these are the subset of branches we care about.
    final RegExp branchRegex = RegExp(r'^beta|^stable|^main|^master|^flutter-.+|^fuchsia.+');
    branches = branches.where((branch) => branch.name.contains(branchRegex)).toList();
    return Body.forJson(branches);
  }
}

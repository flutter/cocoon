// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:cocoon_service/src/model/appengine/branch.dart' as md;
import 'package:process_runner/process_runner.dart';

import '../../cocoon_service.dart';
import '../model/appengine/key_helper.dart';
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
  GetBranches(
    Config config, {
    this.datastoreProvider = DatastoreService.defaultProvider,
    this.processRunner,
  }) : super(config: config);

  final DatastoreServiceProvider datastoreProvider;
  ProcessRunner? processRunner;

  static const String kUpdateBranchParam = 'update';
  static const int kActiveBranchActivityPeriod = 7;

  @override
  Future<Body> get() async {
    final DatastoreService datastore = datastoreProvider(config.db);
    final KeyHelper keyHelper = config.keyHelper;

    final List<md.SerializableBranch> branches = await datastore
        .queryBranches()
        .where((md.Branch b) =>
            DateTime.now().millisecondsSinceEpoch - b.lastActivity! <
            const Duration(days: kActiveBranchActivityPeriod).inMilliseconds)
        .map<md.SerializableBranch>((md.Branch branch) => md.SerializableBranch(branch, keyHelper.encode(branch.key)))
        .toList();
    return Body.forJson(branches);
  }
}

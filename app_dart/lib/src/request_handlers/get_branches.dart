// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:cocoon_service/src/model/appengine/branch.dart';
import 'package:gcloud/db.dart';
import 'package:meta/meta.dart';

import '../model/appengine/key_helper.dart';
import '../request_handling/body.dart';
import '../request_handling/request_handler.dart';
import '../service/build_status_provider.dart';
import '../service/config.dart';
import '../service/datastore.dart';

/// Get currently active branches across all repos.
///
/// Returns all branches with associated key, branch name and repository name, for branches with recent commit acitivies
/// within the past [GetBranches.kActiveBranchActivityPeriod] days.
///
/// GET: /api/public/get-branches
///
///Parameters:
///   update: (string in query) default: 'false'. If update paramter is 'true', update branch's latest ative activitiy timestamp
///           to reflect most recent commit activities.
///
/// Response: Status 200 OK
///{
///   "Branches":[
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
///   ]
///}

@immutable
class GetBranches extends RequestHandler<Body> {
  const GetBranches(
    Config config, {
    this.datastoreProvider = DatastoreService.defaultProvider,
    BuildStatusServiceProvider? buildStatusProvider,
  })  : buildStatusProvider = buildStatusProvider ?? BuildStatusService.defaultProvider,
        super(config: config);

  final DatastoreServiceProvider datastoreProvider;
  final BuildStatusServiceProvider buildStatusProvider;

  static const String kUpdateBranchParam = 'update';
  static const int kActiveBranchActivityPeriod = 7;

  @override
  Future<Body> get() async {
    final DatastoreService datastore = datastoreProvider(config.db);
    final BuildStatusService buildStatusService = buildStatusProvider(datastore);
    final bool updateBranch = (request!.uri.queryParameters[kUpdateBranchParam] ?? 'false').toLowerCase() == 'true';
    final KeyHelper keyHelper = config.keyHelper;

    if (updateBranch) {
      await _updateBranchActivity(datastore, buildStatusService);
    }
    final List<BranchWrapper> branches = await datastore
        .queryBranches()
        .where((Branch b) =>
            DateTime.now().millisecondsSinceEpoch - b.lastActivity! <
            const Duration(days: kActiveBranchActivityPeriod).inMilliseconds)
        .map<BranchWrapper>((Branch branch) => BranchWrapper(branch, keyHelper.encode(branch.key)))
        .toList();
    return Body.forJson(<String, dynamic>{'Branches': branches});
  }

  Future<void> _updateBranchActivity(DatastoreService datastore, BuildStatusService buildStatusService) async {
    final Map<String, int> activeBranchIdWithTimestamp = await buildStatusService.retrieveActiveBranchIds(
      timestamp: DateTime.now().subtract(const Duration(days: kActiveBranchActivityPeriod)).millisecondsSinceEpoch,
    );

    final List<Key<String>> branchKeysToBeUpdated = await datastore
        .queryBranches()
        .where((Branch b) => activeBranchIdWithTimestamp.containsKey(b.key.id))
        .map((Branch b) => b.key)
        .toList();
    final List<Branch> updatedBranches = branchKeysToBeUpdated
        .map((Key<String> k) => Branch(key: k, lastActivity: activeBranchIdWithTimestamp[k.id]!))
        .toList();
    //FOR REVIEW:
    // doing delete and add here, could not find update operation in db.dart
    await datastore.delete(branchKeysToBeUpdated);
    await datastore.insert(updatedBranches);
  }
}

// FOR REVIEW: Probably related to how keyhelper is implementated,
// but I have to add a wrapper class to avoid `Converting object to an encodable object failed: Instance of 'SerializableBranch'` error
class BranchWrapper {
  const BranchWrapper(this.branch, this.key);

  final Branch branch;
  final String key;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'key': key,
      'branch': SerializableBranch(branch).facade,
    };
  }
}

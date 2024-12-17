// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/model/gerrit/commit.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:cocoon_service/src/service/gerrit_service.dart';
import 'package:collection/collection.dart';
import 'package:github/github.dart';
import 'package:http/testing.dart';

import '../datastore/fake_config.dart';
import '../utilities/entity_generators.dart';

/// Fake [GerritService] for use in tests.
class FakeGerritService extends GerritService {
  FakeGerritService({
    this.branchesValue = _defaultBranches,
    this.commitsValue,
  }) : super(
          config: FakeConfig(),
          httpClient:
              MockClient((_) => throw const InternalServerError('FakeGerritService tried to make an http request')),
        );

  List<String> branchesValue;
  static const List<String> _defaultBranches = <String>['main'];

  List<GerritCommit>? commitsValue;
  final List<GerritCommit> _defaultCommits = <GerritCommit>[
    generateGerritCommit('abc', 1),
    generateGerritCommit('cde', 2),
    generateGerritCommit('efg', 3),
  ];

  @override
  Future<List<String>> branches(String repo, String project, {String? filterRegex}) async => branchesValue;

  @override
  Future<Iterable<GerritCommit>> commits(RepositorySlug slug, String branch) async => commitsValue ?? _defaultCommits;

  @override
  Future<void> createBranch(RepositorySlug slug, String branchName, String revision) async => Future.value(null);

  @override
  Future<GerritCommit?> findMirroredCommit(RepositorySlug slug, String sha) async {
    final commits = await this.commits(slug, '');
    return commits.firstWhereOrNull((commit) => commit.commit == sha);
  }
}

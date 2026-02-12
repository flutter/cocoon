// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/model/gerrit/commit.dart';
import 'package:cocoon_service/src/service/gerrit_service.dart';
import 'package:collection/collection.dart';
import 'package:github/github.dart';

import '../utilities/entity_generators.dart';

/// Fake [GerritService] for use in tests.
final class FakeGerritService implements GerritService {
  FakeGerritService({
    this.branchesValue = _defaultBranches,
    List<GerritCommit>? commitsValue,
  }) : commitsValue =
           commitsValue ??
           // New list since these are technically mutable.
           [
             generateGerritCommit('abc', 1),
             generateGerritCommit('cde', 2),
             generateGerritCommit('efg', 3),
           ];

  List<String> branchesValue;
  static const _defaultBranches = ['refs/heads/master'];

  List<GerritCommit> commitsValue;

  @override
  Future<List<String>> branches(
    String repo,
    String project, {
    String? filterRegex,
  }) async => branchesValue;

  @override
  Future<Iterable<GerritCommit>> commits(
    RepositorySlug slug,
    String branch,
  ) async => commitsValue;

  @override
  Future<void> createBranch(
    RepositorySlug slug,
    String branchName,
    String revision,
  ) async => Future.value(null);

  @override
  Future<GerritCommit?> findMirroredCommit(
    RepositorySlug slug,
    String sha,
  ) async {
    final commits = await this.commits(slug, '');
    return commits.firstWhereOrNull((commit) => commit.commit == sha);
  }

  @override
  Future<GerritCommit?> getCommit(RepositorySlug slug, String sha) async {
    final search = commitsValue;
    return search.firstWhereOrNull((r) => r.commit == sha);
  }
}

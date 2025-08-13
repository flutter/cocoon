// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:github/github.dart';
import 'package:googleapis/firestore/v1.dart' as g;
import 'package:meta/meta.dart';

import 'base.dart';

/// Records presubmit test execution.
///
/// For a given GitHub pull request, we store:
/// ```
/// /projects/flutter-dashboard/databases/cocoon/prTestRuns/
///   document: <firebase unique id>
///     pr:   <number>
///     repo: <owner>/<name>
///     sha:  <string>
///     test: <string>
///     runs: <array of PrTestRunResult objects>
/// ```
final class PrTestRuns extends AppDocument<PrTestRuns> {
  /// Description of the document in Firestore.
  static final metadata = AppDocumentMetadata<PrTestRuns>(
    collectionId: 'prTestRuns',
    fromDocument: PrTestRuns.fromDocument,
  );

  @override
  AppDocumentMetadata<PrTestRuns> get runtimeMetadata => metadata;

  /// Create [PrCheckRuns] from a Commit Document.
  factory PrTestRuns.fromDocument(g.Document prCheckRunsDoc) {
    return PrTestRuns._()
      ..fields = prCheckRunsDoc.fields!
      ..name = prCheckRunsDoc.name!;
  }

  // Indexes:
  //
  // - {pr, repo}  --> Used to jump from the Github UI, or provide a nice /flutter/flutter/1234 URL
  // - {sha}       --> Used to lookup all of the tests for a given SHA
  static const _fieldPrNumber = 'pr';
  static const _fieldRepo = 'repo';
  static const _fieldSha = 'sha';
  static const _fieldTestName = 'test';
  static const _fieldRuns = 'runs';

  PrTestRuns._();

  /// The pull-request number.
  int get prNumber => int.parse(fields[_fieldPrNumber]!.integerValue!);

  /// The repository slug associated with this test run.
  RepositorySlug get slug {
    return RepositorySlug.full(fields[_fieldRepo]!.stringValue!);
  }

  /// The commit SHA associated with this test run.
  String get commitSha => fields[_fieldSha]!.stringValue!;

  /// The test name (sometimes called "builder" or "task") name.
  String get testName => fields[_fieldTestName]!.stringValue!;

  /// The results of running [test] for the given [commitSha].
  ///
  /// The returned iterator is guaranteed to be in the same order as the
  /// recorded tests, in a monotonically increasing order (where
  /// [PrTestRunResult.attempt] is `[1, (∞)`), and have an efficient
  /// implementation of [Iterable.elementAt] (no need to convert to a list).
  Iterable<PrTestRunResult> get testRuns {
    final testRuns = fields[_fieldRuns]!.arrayValue!.values ?? const [];
    return testRuns.cast<Map<String, Object?>>().map(
      PrTestRunResult._fromNestedObject,
    );
  }
}

/// A test that was executed as part of [PrTestRuns] commit presubmit.
@immutable
final class PrTestRunResult {
  factory PrTestRunResult._fromNestedObject(Map<String, Object?> object) {
    return PrTestRunResult._(attempt: object['attempt'] as int);
  }

  const PrTestRunResult._({
    required this.attempt, //
  });

  /// Which attempt number this cooresponds to, `[1, (∞)`).
  final int attempt;
}

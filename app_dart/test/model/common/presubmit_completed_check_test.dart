// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:buildbucket/buildbucket_pb.dart';
import 'package:cocoon_common/task_status.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/model/commit_ref.dart';
import 'package:cocoon_service/src/model/common/presubmit_completed_check.dart';
import 'package:cocoon_service/src/model/firestore/base.dart';
import 'package:cocoon_service/src/model/github/checks.dart' as cocoon_checks;
import 'package:cocoon_service/src/service/luci_build_service/user_data.dart';
import 'package:github/github.dart';
import 'package:test/test.dart';

void main() {
  useTestLoggerPerTest();

  group('PresubmitCompletedCheck', () {
    const sha = 'abc';
    final slug = RepositorySlug('flutter', 'flutter');

    test('fromCheckRun creates correct instance', () {
      final checkRun = const cocoon_checks.CheckRun(
        id: 1,
        name: 'test_check',
        headSha: sha,
        conclusion: 'success',
      );

      final check = PresubmitCompletedCheck.fromCheckRun(checkRun, slug);

      expect(check.name, 'test_check');
      expect(check.sha, sha);
      expect(check.slug, slug);
      expect(check.status, TaskStatus.succeeded);
      expect(check.isMergeGroup, false);
      expect(check.checkRunId, 1);
      expect(check.checkSuiteId, null);
      expect(check.headBranch, null);
      expect(check.isUnifiedCheckRun, false);
      expect(check.checkRun.name, 'test_check');
    });

    test('fromBuild creates correct unified check', () {
      final build = Build(
        builder: BuilderID(builder: 'test_builder'),
        status: Status.SUCCESS,
      );

      final userData = PresubmitUserData(
        commit: CommitRef(
          slug: slug,
          sha: sha,
          branch: 'gh-readonly-queue/master/pr-123-abc',
        ),
        stage: CiStage.fusionEngineBuild,
        pullRequestNumber: 1,
        guardCheckRunId: 123,
        checkSuiteId: 456,
      );

      final check = PresubmitCompletedCheck.fromBuild(build, userData);

      expect(check.name, 'test_builder');
      expect(check.sha, sha);
      expect(check.slug, slug);
      expect(check.status, TaskStatus.succeeded);
      expect(check.isMergeGroup, true);
      expect(check.checkRunId, 123);
      expect(check.checkSuiteId, 456);
      expect(check.headBranch, 'gh-readonly-queue/master/pr-123-abc');
      expect(check.isUnifiedCheckRun, true);
      expect(check.checkRun.name, 'Merge Queue Guard');
    });

    test('fromBuild creates correct legacy check', () {
      final build = Build(
        builder: BuilderID(builder: 'test_builder'),
        status: Status.SUCCESS,
      );

      final userData = PresubmitUserData(
        commit: CommitRef(
          slug: slug,
          sha: sha,
          branch: 'gh-readonly-queue/master/pr-123-abc',
        ),
        stage: CiStage.fusionEngineBuild,
        pullRequestNumber: 1,
        checkRunId: 123,
        checkSuiteId: 456,
      );

      final check = PresubmitCompletedCheck.fromBuild(build, userData);

      expect(check.name, 'test_builder');
      expect(check.sha, sha);
      expect(check.slug, slug);
      expect(check.status, TaskStatus.succeeded);
      expect(check.isMergeGroup, true);
      expect(check.checkRunId, 123);
      expect(check.checkSuiteId, 456);
      expect(check.headBranch, 'gh-readonly-queue/master/pr-123-abc');
      expect(check.isUnifiedCheckRun, false);
      expect(check.checkRun.name, 'test_builder');
    });
  });
}

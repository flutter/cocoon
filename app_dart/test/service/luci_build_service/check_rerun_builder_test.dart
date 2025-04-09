// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:cocoon_common_test/cocoon_common_test.dart';
import 'package:cocoon_server/logging.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/model/firestore/pr_check_runs.dart';
import 'package:cocoon_service/src/service/cache_service.dart';
import 'package:cocoon_service/src/service/luci_build_service.dart';
import 'package:cocoon_service/src/service/luci_build_service/engine_artifacts.dart';
import 'package:cocoon_service/src/service/luci_build_service/user_data.dart';
import 'package:github/github.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../src/datastore/fake_config.dart';
import '../../src/model/ci_yaml_matcher.dart';
import '../../src/request_handling/fake_pubsub.dart';
import '../../src/service/fake_firestore_service.dart';
import '../../src/service/fake_gerrit_service.dart';
import '../../src/utilities/entity_generators.dart';
import '../../src/utilities/mocks.mocks.dart';

/// Tests [LuciBuildService] public API related to rerunning TOT test failures.
///
/// Specifically:
/// - [LuciBuildService.checkRerunBuilder]
void main() {
  useTestLoggerPerTest();

  // System under test:
  late LuciBuildService luci;

  // Dependencies (mocked/faked if necessary):
  late MockBuildBucketClient mockBuildBucketClient;
  late MockGithubChecksUtil mockGithubChecksUtil;
  late FakeFirestoreService firestoreService;
  late FakePubSub pubSub;

  setUp(() {
    mockBuildBucketClient = MockBuildBucketClient();
    mockGithubChecksUtil = MockGithubChecksUtil();
    firestoreService = FakeFirestoreService();
    pubSub = FakePubSub();

    luci = LuciBuildService(
      cache: CacheService(inMemory: true),
      config: FakeConfig(firestoreService: firestoreService),
      buildBucketClient: mockBuildBucketClient,
      githubChecksUtil: mockGithubChecksUtil,
      pubsub: pubSub,
    );
  });

  test('runs successfully', () async {
    // await expectLater(luci.checkRerunBuilder(), completion(isTrue));
  });

  test('can rerun a test failed builder', () async {});

  test('can rerun an infra failed builder', () async {});

  test('skips rerunning when an exception occurs', () async {});

  test('skips rerunning a successful builder', () async {});

  test('skips rerunning if past retry limit', () async {});

  test('skips rerunning when builder is not in tip-of-tree', () async {});
}

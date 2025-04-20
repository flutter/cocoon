// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/service/cache_service.dart';
import 'package:cocoon_service/src/service/luci_build_service.dart';
import 'package:fixnum/fixnum.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../src/fake_config.dart';
import '../../src/request_handling/fake_pubsub.dart';
import '../../src/service/fake_firestore_service.dart';
import '../../src/service/fake_gerrit_service.dart';
import '../../src/utilities/entity_generators.dart';
import '../../src/utilities/mocks.mocks.dart';

/// Tests [LuciBuildService] public API related to fetching prod-bot builds.
///
/// Specifically:
/// - [LuciBuildService.cancelBuilds]
void main() {
  useTestLoggerPerTest();

  late LuciBuildService luci;

  // Dependencies (mocked/faked if necessary):
  late MockBuildBucketClient mockBuildBucketClient;
  late MockGithubChecksUtil mockGithubChecksUtil;
  late FakeFirestoreService firestoreService;
  late FakePubSub pubSub;

  final pullRequest = generatePullRequest(id: 1, repo: 'cocoon');

  setUp(() {
    mockBuildBucketClient = MockBuildBucketClient();
    mockGithubChecksUtil = MockGithubChecksUtil();
    firestoreService = FakeFirestoreService();
    pubSub = FakePubSub();

    luci = LuciBuildService(
      cache: CacheService(inMemory: true),
      config: FakeConfig(firestoreService: firestoreService),
      gerritService: FakeGerritService(),
      buildBucketClient: mockBuildBucketClient,
      githubChecksUtil: mockGithubChecksUtil,
      pubsub: pubSub,
    );
  });

  test('does nothing and logs if no builds are founds by a PR', () async {
    when(mockBuildBucketClient.batch(any)).thenAnswer((i) async {
      expect(i.positionalArguments, [
        isA<bbv2.BatchRequest>().having((b) => b.requests, 'requests', [
          isA<bbv2.BatchRequest_Request>().having(
            (r) => r.hasSearchBuilds(),
            'hasSearchBuilds()',
            isTrue,
          ),
        ]),
      ]);
      return bbv2.BatchResponse(responses: []);
    });

    await luci.cancelBuilds(pullRequest: pullRequest, reason: 'New Builds');

    verify(mockBuildBucketClient.batch(any)).called(1);
  });

  test('cancels scheduled builds', () async {
    late final bbv2.CancelBuildRequest cancelRequest;

    when(mockBuildBucketClient.batch(any)).thenAnswer((i) async {
      final [bbv2.BatchRequest batch] = i.positionalArguments;
      final [bbv2.BatchRequest_Request request] = batch.requests;

      if (request.hasSearchBuilds()) {
        return bbv2.BatchResponse(
          responses: [
            bbv2.BatchResponse_Response(
              searchBuilds: bbv2.SearchBuildsResponse(
                builds: [
                  generateBbv2Build(
                    Int64(998),
                    name: 'Linux',
                    status: bbv2.Status.STARTED,
                  ),
                ],
              ),
            ),
          ],
        );
      }

      if (request.hasCancelBuild()) {
        cancelRequest = request.cancelBuild;
        return bbv2.BatchResponse();
      }

      fail('Unexpected request: $request');
    });

    await luci.cancelBuilds(pullRequest: pullRequest, reason: 'New Builds');

    expect(
      cancelRequest,
      isA<bbv2.CancelBuildRequest>()
          .having((r) => r.id, 'id', Int64(998))
          .having(
            (r) => r.summaryMarkdown,
            'summaryMarkdown',
            contains('New Builds'),
          ),
    );
  });
}

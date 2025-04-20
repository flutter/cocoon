// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/service/cache_service.dart';
import 'package:cocoon_service/src/service/luci_build_service.dart';
import 'package:fixnum/fixnum.dart';
import 'package:github/github.dart' as gh;
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../src/fake_config.dart';
import '../../src/request_handling/fake_pubsub.dart';
import '../../src/service/fake_gerrit_service.dart';
import '../../src/utilities/entity_generators.dart';
import '../../src/utilities/mocks.mocks.dart';

/// Tests [LuciBuildService] public API related to fetching [bbv2.Build]s.
///
/// Specifically:
/// - [LuciBuildService.getAvailableBuilderSet]
/// - [LuciBuildService.getTryBuildsByPullRequest]
/// - [LuciBuildService.getProdBuilds]
/// - [LuciBuildService.getBuildById]
void main() {
  useTestLoggerPerTest();

  // System under test:
  late LuciBuildService luci;

  // Dependencies (mocked/faked if necessary):
  late CacheService cacheService;
  late MockBuildBucketClient mockBuildBucketClient;

  setUp(() {
    mockBuildBucketClient = MockBuildBucketClient();
    cacheService = CacheService(inMemory: true);

    luci = LuciBuildService(
      config: FakeConfig(),
      cache: cacheService,
      gerritService: FakeGerritService(),
      buildBucketClient: mockBuildBucketClient,
      pubsub: FakePubSub(),
    );
  });

  final exampleLinuxBuild = generateBbv2Build(
    Int64(998),
    name: 'Linux',
    bucket: 'try',
    status: bbv2.Status.STARTED,
  );

  test('getProdBuilds searches using "batch"', () async {
    when(mockBuildBucketClient.batch(any)).thenAnswer((i) async {
      final [bbv2.BatchRequest request] = i.positionalArguments;
      expect(request.requests, [
        isA<bbv2.BatchRequest_Request>().having(
          (r) => r.searchBuilds,
          'searchBuilds',
          isA<bbv2.SearchBuildsRequest>().having(
            (r) => r.predicate,
            'predicate',
            isA<bbv2.BuildPredicate>().having(
              (r) => r.builder,
              'builder',
              isA<bbv2.BuilderID>()
                  .having((r) => r.project, 'project', 'flutter')
                  .having((r) => r.bucket, 'bucket', 'prod')
                  .having((r) => r.builder, 'builder', 'abcd'),
            ),
          ),
        ),
      ]);

      return bbv2.BatchResponse(
        responses: [
          bbv2.BatchResponse_Response(
            searchBuilds: bbv2.SearchBuildsResponse(
              builds: [exampleLinuxBuild],
            ),
          ),
        ],
      );
    });

    await expectLater(
      luci.getProdBuilds(sha: 'shasha', builderName: 'abcd'),
      completion([exampleLinuxBuild]),
    );
  });

  test('finds a try build by a pull request', () async {
    when(mockBuildBucketClient.batch(any)).thenAnswer((i) async {
      final [bbv2.BatchRequest request] = i.positionalArguments;
      expect(request.requests, [
        isA<bbv2.BatchRequest_Request>().having(
          (r) => r.searchBuilds,
          'searchBuilds',
          isA<bbv2.SearchBuildsRequest>().having(
            (r) => r.predicate,
            'predicate',
            isA<bbv2.BuildPredicate>().having(
              (r) => r.builder,
              'builder',
              isA<bbv2.BuilderID>()
                  .having((r) => r.project, 'project', 'flutter')
                  .having((r) => r.bucket, 'bucket', 'try')
                  .having((r) => r.builder, 'builder', isEmpty),
            ),
          ),
        ),
      ]);

      return bbv2.BatchResponse(
        responses: [
          bbv2.BatchResponse_Response(
            searchBuilds: bbv2.SearchBuildsResponse(
              builds: [exampleLinuxBuild],
            ),
          ),
        ],
      );
    });

    await expectLater(
      luci.getTryBuildsByPullRequest(
        pullRequest: gh.PullRequest(
          id: 998,
          number: 1234,
          base: gh.PullRequestHead(
            repo: gh.Repository(fullName: 'flutter/cocoon'),
          ),
        ),
      ),
      completion([exampleLinuxBuild]),
    );
  });

  group('finds all available builders', () {
    test('uses a cached value if present', () async {
      await cacheService.set(
        LuciBuildService.subCacheName,
        'builderlist/project/bucket',
        Uint8List.fromList({'Foo', 'Bar', 'Baz'}.join(',').codeUnits),
      );

      await expectLater(
        luci.getAvailableBuilderSet(project: 'project', bucket: 'bucket'),
        completion({'Foo', 'Bar', 'Baz'}),
      );
    });

    test('fetches builders from build bucket and stores in cache', () async {
      when(mockBuildBucketClient.listBuilders(any)).thenAnswer((i) async {
        final [bbv2.ListBuildersRequest request] = i.positionalArguments;
        expect(
          request,
          isA<bbv2.ListBuildersRequest>()
              .having((r) => r.project, 'project', 'project-id')
              .having((r) => r.bucket, 'bucket', 'bucket-id'),
        );
        return bbv2.ListBuildersResponse(
          builders: [
            bbv2.BuilderItem(id: bbv2.BuilderID(builder: 'Foo')),
            bbv2.BuilderItem(id: bbv2.BuilderID(builder: 'Bar')),
            bbv2.BuilderItem(id: bbv2.BuilderID(builder: 'Baz')),
          ],
        );
      });

      await expectLater(
        luci.getAvailableBuilderSet(project: 'project-id', bucket: 'bucket-id'),
        completion({'Foo', 'Bar', 'Baz'}),
      );

      // Second call should be to cache.
      await expectLater(
        luci.getAvailableBuilderSet(project: 'project-id', bucket: 'bucket-id'),
        completion({'Foo', 'Bar', 'Baz'}),
      );

      verify(mockBuildBucketClient.listBuilders(any)).called(1);
    });

    test('returns multiple pages of responses', () async {
      when(mockBuildBucketClient.listBuilders(any)).thenAnswer((i) async {
        final [bbv2.ListBuildersRequest request] = i.positionalArguments;
        expect(
          request,
          isA<bbv2.ListBuildersRequest>()
              .having((r) => r.project, 'project', 'project-id')
              .having((r) => r.bucket, 'bucket', 'bucket-id'),
        );
        return switch (request.pageToken) {
          'page-3' => bbv2.ListBuildersResponse(
            builders: [bbv2.BuilderItem(id: bbv2.BuilderID(builder: 'Baz'))],
          ),
          'page-2' => bbv2.ListBuildersResponse(
            builders: [bbv2.BuilderItem(id: bbv2.BuilderID(builder: 'Bar'))],
            nextPageToken: 'page-3',
          ),
          '' => bbv2.ListBuildersResponse(
            builders: [bbv2.BuilderItem(id: bbv2.BuilderID(builder: 'Foo'))],
            nextPageToken: 'page-2',
          ),
          _ => fail('Unexpected pageToken: "${request.pageToken}"'),
        };
      });

      await expectLater(
        luci.getAvailableBuilderSet(project: 'project-id', bucket: 'bucket-id'),
        completion({'Foo', 'Bar', 'Baz'}),
      );
    });
  });

  test('gets a build by ID', () async {
    when(mockBuildBucketClient.getBuild(any)).thenAnswer((i) async {
      final [bbv2.GetBuildRequest request] = i.positionalArguments;

      expect(request.id, Int64(1001));
      expect(
        request.mask,
        bbv2.BuildMask(fields: bbv2.FieldMask(paths: ['foo', 'bar', 'baz'])),
      );

      return exampleLinuxBuild;
    });

    await expectLater(
      luci.getBuildById(
        Int64(1001),
        buildMask: bbv2.BuildMask(
          fields: bbv2.FieldMask(paths: ['foo', 'bar', 'baz']),
        ),
      ),
      completion(exampleLinuxBuild),
    );
  });
}

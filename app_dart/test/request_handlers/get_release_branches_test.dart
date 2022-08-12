// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_service/src/request_handlers/get_release_branches.dart';
import 'package:cocoon_service/src/request_handling/body.dart';
import 'package:github/github.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';
import '../src/request_handling/fake_http.dart';
import '../src/request_handling/request_handler_tester.dart';
import '../src/utilities/entity_generators.dart';
import '../src/utilities/mocks.dart';

void main() {
  group('get release branches', () {
    late FakeConfig config;
    late RequestHandlerTester tester;
    late GetReleaseBranches handler;
    late FakeHttpRequest request;
    late MockRepositoriesService mockRepositoriesService;

    Future<T?> decodeHandlerBody<T>() async {
      final Body body = await tester.get(handler);
      return await utf8.decoder.bind(body.serialize() as Stream<List<int>>).transform(json.decoder).single as T?;
    }

    setUp(() {
      request = FakeHttpRequest();
      tester = RequestHandlerTester(request: request);

      final MockGitHub mockGitHubClient = MockGitHub();
      mockRepositoriesService = MockRepositoriesService();
      when(mockGitHubClient.repositories).thenReturn(mockRepositoriesService);

      config = FakeConfig(githubClient: mockGitHubClient);
      handler = GetReleaseBranches(
        config,
      );
    });

    test('return beta, stable, and google 3 branches', () async {
      final List<Stream<Tag>> tagResponses = <Stream<Tag>>[
        Stream.fromIterable(
            <Tag>[generateTag(1, name: '3.3.0-0.3.pre', sha: '1'), generateTag(2, name: '3.2.1', sha: '2')]),
        Stream.fromIterable(<Tag>[]),
      ];
      when(mockRepositoriesService.listTags(any,
              page: anyNamed('page'), pages: anyNamed("pages"), perPage: anyNamed("perPage")))
          .thenAnswer((Invocation invocation) {
        return tagResponses.removeAt(0);
      });
      when(mockRepositoriesService.listBranches(any)).thenAnswer((Invocation invocation) {
        return Stream.fromIterable([
          generateBranch(3, name: 'flutter-1.26-candidate.11 ', sha: '3'),
          generateBranch(4, name: 'not_a_release_branch', sha: '4')
        ]);
      });
      final Map<String, dynamic> result = (await decodeHandlerBody())!;
      expect(result['Beta'].length, 1);
      expect(result['Beta'].single, '1');
      expect(result['Stable'].length, 1);
      expect(result['Stable'].single, '2');
      expect(result['googleBraches'].length, 1);
      expect(result['googleBraches'].single, '3');
    });

    test('find latest branches based on version number', () async {
      final List<Stream<Tag>> tagResponses = <Stream<Tag>>[
        Stream.fromIterable(
            <Tag>[generateTag(1, name: '3.3.0-0.3.pre', sha: '1'), generateTag(2, name: '3.2.1', sha: '2')]),
        Stream.fromIterable(
            <Tag>[generateTag(3, name: '2.2.0-0.6.pre', sha: '3'), generateTag(4, name: '1.2.9', sha: '4')]),
        Stream.fromIterable(
            <Tag>[generateTag(5, name: '2.9.8-9.3.pre', sha: '5'), generateTag(6, name: '2.6.7', sha: '6')]),
        Stream.fromIterable(<Tag>[]),
      ];
      when(mockRepositoriesService.listTags(any,
              page: anyNamed('page'), pages: anyNamed("pages"), perPage: anyNamed("perPage")))
          .thenAnswer((Invocation invocation) {
        return tagResponses.removeAt(0);
      });
      when(mockRepositoriesService.listBranches(any)).thenAnswer((Invocation invocation) {
        return Stream.fromIterable([
          generateBranch(3, name: 'flutter-1.26-candidate.11 ', sha: '3'),
          generateBranch(4, name: 'not_a_release_branch', sha: '4')
        ]);
      });
      final Map<String, dynamic> result = (await decodeHandlerBody())!;
      expect(result['Beta'].length, 3);
      expect(result['Beta'], ['1', '5', '3']);
      expect(result['Stable'].length, 3);
      expect(result['Stable'], ['2', '6', '4']);
    });
  });
}

// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_service/src/request_handlers/get_release_branches.dart';
import 'package:cocoon_service/src/request_handling/body.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';
import '../src/request_handling/fake_http.dart';
import '../src/request_handling/request_handler_tester.dart';
import '../src/utilities/mocks.dart';

void main() {
  group('get release branches', () {
    late FakeConfig config;
    late RequestHandlerTester tester;
    late GetReleaseBranches handler;
    late FakeHttpRequest request;
    late MockRepositoriesService mockRepositoriesService;
    late MockBranchService branchService;

    Future<T?> decodeHandlerBody<T>() async {
      final Body body = await tester.get(handler);
      return await utf8.decoder.bind(body.serialize() as Stream<List<int>>).transform(json.decoder).single as T?;
    }

    setUp(() {
      request = FakeHttpRequest();
      tester = RequestHandlerTester(request: request);
      branchService = MockBranchService();

      final MockGitHub mockGitHubClient = MockGitHub();
      mockRepositoriesService = MockRepositoriesService();
      when(mockGitHubClient.repositories).thenReturn(mockRepositoriesService);

      config = FakeConfig(githubClient: mockGitHubClient);
      handler = GetReleaseBranches(
        config,
        branchService: branchService,
      );
    });

    test('return beta, stable, and google 3 branches', () async {
      when(branchService.getStableBetaDevBranches(github: anyNamed("github"), slug: anyNamed("slug")))
          .thenAnswer((Invocation invocation) {
        return Future<List<String>>.value(
            <String>["flutter-2.13-candidate.0", "flutter-3.2-candidate.5", "flutter-3.4-candidate.5"]);
      });
      final List<dynamic> result = (await decodeHandlerBody())!;
      expect(result.length, 3);
      expect(result[0]['branch'], "flutter-2.13-candidate.0");
      expect(result[0]['name'], "stable");
      expect(result[1]['branch'], "flutter-3.2-candidate.5");
      expect(result[1]['name'], "beta");
      expect(result[2]['branch'], "flutter-3.4-candidate.5");
      expect(result[2]['name'], "dev");
    });
  });
}

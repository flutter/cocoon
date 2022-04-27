// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:cocoon_service/src/model/gerrit/commit.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:cocoon_service/src/service/branch_service.dart';
import 'package:cocoon_service/src/service/config.dart';
import 'package:cocoon_service/src/service/gerrit_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:test/test.dart';

import '../src/service/fake_auth_client.dart';
import '../src/utilities/matchers.dart';

void main() {
  late MockClient mockHttpClient;
  late GerritService gerritService;
  group('getBranches', () {
    test('Too many retries raise an exception', () async {
      mockHttpClient = MockClient((_) async => http.Response(')]}\'\n[]', HttpStatus.forbidden));
      gerritService = GerritService(httpClient: mockHttpClient);
      try {
        await gerritService.branches(
          'myhost',
          'a/b/c',
          subString: 'flutter-',
        );
      } catch (e) {
        expect(e, isA<RetryException>());
      }
    });
    test('Returns a list of branches', () async {
      const String body =
          ')]}\'\n[{"web_links":[{"name":"browse","url":"https://a.com/branch_a","target":"_blank"}],"ref":"refs/heads/branch_a","revision":"0bc"}]';
      mockHttpClient = MockClient((_) async => http.Response(body, HttpStatus.ok));
      gerritService = GerritService(httpClient: mockHttpClient);
      final List<String> branches = await gerritService.branches(
        'myhost',
        'a/b/c',
        subString: 'flutter-',
      );
      expect(branches, equals(<String>['refs/heads/branch_a']));
    });

    test('No results return an empty list', () async {
      mockHttpClient = MockClient((_) async => http.Response(')]}\'\n[]', HttpStatus.ok));
      gerritService = GerritService(httpClient: mockHttpClient);
      final List<String> branches = await gerritService.branches(
        'myhost',
        'a/b/c',
        subString: 'flutter-',
      );
      expect(branches, equals(<String>[]));
    });
  });

  group('commits', () {
    test('Returns a list of commits', () async {
      mockHttpClient = MockClient((_) async => http.Response(commitsListJson, HttpStatus.ok));
      gerritService = GerritService(httpClient: mockHttpClient);
      final Iterable<GerritCommit> commits = await gerritService.commits(Config.recipesSlug, 'main');
      expect(commits.length, 1);
      final GerritCommit commit = commits.single;
      expect(commit.author?.email, 'dash@flutter.dev');
      expect(commit.author?.name, 'Dash');
      expect(commit.author?.time, isNotNull);
      final DateTime time = commit.author!.time!;
      final DateTime expectedTime = DateTime.utc(2022, 7, 12, 17, 21, 25);
      expect(time, expectedTime);
    });
  });

  group('createBranch', () {
    test('ok response', () async {
      mockHttpClient = MockClient((_) async => http.Response(createBranchJson, HttpStatus.ok));
      gerritService = GerritService(
        httpClient: mockHttpClient,
        authClientProvider: ({
          Client? baseClient,
          required List<String> scopes,
        }) async =>
            FakeAuthClient(baseClient!),
      );

      await gerritService.createBranch(
          Config.recipesSlug, 'flutter-2.13-candidate.0', '00439ab49a991db42595f14078adb9811a6f60c6');
    });

    test('unexpected response', () async {
      mockHttpClient = MockClient((_) async => http.Response(createBranchJson, HttpStatus.ok));
      gerritService = GerritService(
        httpClient: mockHttpClient,
        authClientProvider: ({
          Client? baseClient,
          required List<String> scopes,
        }) async =>
            FakeAuthClient(baseClient!),
      );
      expect(() async => await gerritService.createBranch(Config.recipesSlug, 'flutter-2.13-candidate.0', 'abc'),
          throwsExceptionWith<InternalServerError>('Failed to create branch'));
    });
  });
}

const String commitsListJson = ''')]}'
{
  "log": [
    {
      "commit": "7a702db7c1c8dc057d95e0d23849c885b3463ff3",
      "tree": "9c1529c1e92b3431534dcbf01d2b63547b73b005",
      "parents": [
        "289edf3f90678e7ce1319aa1e8a57d7506c461d1"
      ],
      "author": {
        "name": "Dash",
        "email": "dash@flutter.dev",
        "time": "Tue Jul 12 17:21:25 2022 +0000"
      },
      "committer": {
        "name": "CQ Bot Account",
        "email": "flutter-scoped@luci-project-accounts.iam.gserviceaccount.com",
        "time": "Tue Jul 12 17:21:25 2022 +0000"
      },
      "message": "My first recipe change\\n\\ntested through `led get-builder"
    }
  ],
  "next": "00439ab49a991db42595f14078adb9811a6f60c6"
}
''';

const String createBranchJson = ''')]}'
{
  "revision": "00439ab49a991db42595f14078adb9811a6f60c6"
}
''';

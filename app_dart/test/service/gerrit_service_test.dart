// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:cocoon_service/src/model/gerrit/commit.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:cocoon_service/src/service/branch_service.dart';
import 'package:cocoon_service/src/service/config.dart';
import 'package:cocoon_service/src/service/gerrit_service.dart';
import 'package:github/github.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';
import '../src/service/fake_auth_client.dart';
import '../src/utilities/matchers.dart';

void main() {
  late MockClient mockHttpClient;
  late GerritService gerritService;
  group('getBranches', () {
    test('Too many retries raise an exception', () async {
      mockHttpClient = MockClient((_) async => http.Response(')]}\'\n[]', HttpStatus.forbidden));
      gerritService = GerritService(config: FakeConfig(), httpClient: mockHttpClient);
      try {
        await gerritService.branches(
          'myhost',
          'a/b/c',
          filterRegex: 'flutter-*',
        );
      } catch (e) {
        expect(e, isA<RetryException>());
      }
    });
    test('Returns a list of branches', () async {
      Request? requestAux;
      const String body =
          ')]}\'\n[{"web_links":[{"name":"browse","url":"https://a.com/branch_a","target":"_blank"}],"ref":"refs/heads/branch_a","revision":"0bc"}]';
      mockHttpClient = MockClient((Request request) async {
        requestAux = request;
        return http.Response(body, HttpStatus.ok);
      });
      gerritService = GerritService(config: FakeConfig(), httpClient: mockHttpClient);
      final List<String> branches = await gerritService.branches(
        'myhost',
        'a/b/c',
        filterRegex: 'flutter-*|fuchsia*',
      );
      expect(branches, equals(<String>['refs/heads/branch_a']));
      expect(requestAux!.url.queryParameters, equals(<dynamic, dynamic>{'r': 'flutter-*|fuchsia*'}));
    });

    test('No results return an empty list', () async {
      mockHttpClient = MockClient((_) async => http.Response(')]}\'\n[]', HttpStatus.ok));
      gerritService = GerritService(config: FakeConfig(), httpClient: mockHttpClient);
      final List<String> branches = await gerritService.branches(
        'myhost',
        'a/b/c',
        filterRegex: 'flutter-',
      );
      expect(branches, equals(<String>[]));
    });
  });

  group('commits', () {
    test('Returns a list of commits', () async {
      mockHttpClient = MockClient((_) async => http.Response(commitsListJson, HttpStatus.ok));
      gerritService = GerritService(config: FakeConfig(), httpClient: mockHttpClient);
      final Iterable<GerritCommit> commits = await gerritService.commits(Config.recipesSlug, 'main');
      expect(commits.length, 1);
      final GerritCommit commit = commits.single;
      expect(commit.author?.email, 'dash@flutter.dev');
      expect(commit.author?.name, 'Dash');
      expect(commit.author?.time, isNotNull);
      expect(commit.committer?.email, 'flutter-scoped@luci-project-accounts.iam.gserviceaccount.com');
      expect(commit.committer?.name, 'CQ Bot Account');
      expect(commit.committer?.time, isNotNull);
      final DateTime time = commit.author!.time!;
      final DateTime expectedTime = DateTime(2023, 4, 20, 18, 00, 14);
      expect(time, expectedTime);
    });
  });

  group('getCommit', () {
    test('Returns a commit', () async {
      mockHttpClient = MockClient((_) async => http.Response(getCommitJson, HttpStatus.ok));
      gerritService = GerritService(config: FakeConfig(), httpClient: mockHttpClient);
      final GerritCommit? commit = await gerritService.getCommit(
        RepositorySlug('flutter', 'flutter'),
        '7a702db7c1c8dc057d95e0d23849c885b3463ff3',
      );
      expect(commit, isNotNull);
      expect(commit!.author?.email, 'dash@flutter.dev');
      expect(commit.author?.name, 'Dash');
      expect(commit.author?.time, isNotNull);
      final DateTime time = commit.author!.time!;
      final DateTime expectedTime = DateTime(2023, 4, 20, 18, 0, 14);
      expect(time, expectedTime);
    });

    test('Uses percent-encoding for project name', () async {
      mockHttpClient = MockClient((request) async {
        expect(request.url.path, startsWith('/projects/mirrors%2Fflutter'));
        return http.Response(getCommitJson, HttpStatus.ok);
      });
      gerritService = GerritService(config: FakeConfig(), httpClient: mockHttpClient);
      final commit = await gerritService.getCommit(
        RepositorySlug('flutter', 'mirrors/flutter'),
        '7a702db7c1c8dc057d95e0d23849c885b3463ff3',
      );
      expect(commit, isNotNull);
    });
  });

  group('findMirroredCommit', () {
    test('Uses matching slug for GoB mirror', () async {
      mockHttpClient = MockClient((request) async {
        expect(request.url.path, startsWith('/projects/mirrors%2Fpackages'));
        return http.Response(getCommitJson, HttpStatus.ok);
      });
      gerritService = GerritService(config: FakeConfig(), httpClient: mockHttpClient);
      final commit = await gerritService.findMirroredCommit(
        RepositorySlug('flutter', 'packages'),
        '7a702db7c1c8dc057d95e0d23849c885b3463ff3',
      );
      expect(commit, isNotNull);
    });
  });

  group('createBranch', () {
    test('ok response', () async {
      mockHttpClient = MockClient((_) async => http.Response(createBranchJson, HttpStatus.ok));
      gerritService = GerritService(
        config: FakeConfig(),
        httpClient: mockHttpClient,
        authClientProvider: ({
          Client? baseClient,
          required List<String> scopes,
        }) async =>
            FakeAuthClient(baseClient!),
        retryDelay: Duration.zero,
      );

      await gerritService.createBranch(
        Config.recipesSlug,
        'flutter-2.13-candidate.0',
        '00439ab49a991db42595f14078adb9811a6f60c6',
      );
    });

    test('unexpected response', () async {
      mockHttpClient = MockClient((_) async => http.Response(createBranchJson, HttpStatus.ok));
      gerritService = GerritService(
        config: FakeConfig(),
        httpClient: mockHttpClient,
        authClientProvider: ({
          Client? baseClient,
          required List<String> scopes,
        }) async =>
            FakeAuthClient(baseClient!),
        retryDelay: Duration.zero,
      );
      expect(
        () async => gerritService.createBranch(Config.recipesSlug, 'flutter-2.13-candidate.0', 'abc'),
        throwsExceptionWith<InternalServerError>('Failed to create branch'),
      );
    });

    test('retries non-200 responses', () async {
      int attempts = 0;
      mockHttpClient = MockClient((_) async {
        attempts = attempts + 1;
        // Only send a failed response on the first attempt
        if (attempts == 1) {
          return http.Response('error', HttpStatus.internalServerError);
        }
        return http.Response(createBranchJson, HttpStatus.accepted);
      });
      gerritService = GerritService(
        config: FakeConfig(),
        httpClient: mockHttpClient,
        authClientProvider: ({
          Client? baseClient,
          required List<String> scopes,
        }) async =>
            FakeAuthClient(baseClient!),
        retryDelay: Duration.zero,
      );
      await gerritService.createBranch(
        Config.recipesSlug,
        'flutter-2.13-candidate.0',
        '00439ab49a991db42595f14078adb9811a6f60c6',
      );
      expect(attempts, 2);
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
        "time": "Tue Apr 20 18:00:14 2023 +0000"
      },
      "committer": {
        "name": "CQ Bot Account",
        "email": "flutter-scoped@luci-project-accounts.iam.gserviceaccount.com",
        "time": "Tue Apr 20 18:00:14 2023 +0000"
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

const String getCommitJson = ''')]}'
{
  "commit": "7a702db7c1c8dc057d95e0d23849c885b3463ff3",
  "parents": [
    {
      "commit": "1eee2c9d8f352483781e772f35dc586a69ff5646",
      "subject": "Migrate contributor agreements to All-Projects."
    }
  ],
  "author": {
    "name": "Dash",
    "email": "dash@flutter.dev",
    "time": "Wed Apr 20 18:00:14 2023 +0000"
  },
  "committer": {
    "name": "CQ Bot Account",
    "email": "flutter-scoped@luci-project-accounts.iam.gserviceaccount.com",
    "time": "Wed Apr 20 18:00:14 2023 +0000"
  },
  "subject": "Use an EventBus to manage star icons",
  "message": "Use an EventBus to manage star icons\\n\\nImage widgets that need to ..."
}
''';

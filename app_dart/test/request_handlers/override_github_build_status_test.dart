// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:appengine/appengine.dart';
import 'package:cocoon_service/src/model/appengine/github_tree_status_override.dart';
import 'package:cocoon_service/src/request_handlers/override_github_build_status.dart';
import 'package:cocoon_service/src/request_handling/body.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:gcloud/db.dart';
import 'package:github/github.dart';
import 'package:googleapis/bigquery/v2.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_cocoon_config.dart';
import '../src/datastore/fake_datastore.dart';
import '../src/request_handling/api_request_handler_tester.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/request_handling/fake_http.dart';
import '../src/request_handling/fake_logging.dart';
import '../src/service/fake_github_service.dart';
import '../src/utilities/mocks.dart';

void main() {
  group('PushBuildStatusToGithub', () {
    FakeConfig config;
    FakeClientContext clientContext;
    FakeAuthenticatedContext authContext;
    FakeAuthenticationProvider auth;
    FakeDatastoreDB db;
    FakeLogging log;
    FakeHttpRequest request;
    ApiRequestHandlerTester tester;
    OverrideGitHubBuildStatus handler;
    MockJobsResourceApi jobsResourceApi;
    List<int> githubPullRequests;
    MockRepositoriesService repositoriesService;
    int timeStamp;

    List<PullRequest> pullRequestList(String branch) {
      expect(branch, 'master');
      final List<PullRequest> pullRequests = <PullRequest>[];
      for (int pr in githubPullRequests) {
        pullRequests.add(PullRequest()
          ..number = pr
          ..head = (PullRequestHead()..sha = pr.toString()));
      }
      return pullRequests;
    }

    setUp(() {
      timeStamp = DateTime.now().millisecondsSinceEpoch;
      clientContext = FakeClientContext();
      authContext = FakeAuthenticatedContext(clientContext: clientContext);
      auth = FakeAuthenticationProvider(clientContext: clientContext);
      final FakeGithubService githubService = FakeGithubService();
      db = FakeDatastoreDB();
      jobsResourceApi = MockJobsResourceApi();
      config = FakeConfig(
        jobsResourceApi: jobsResourceApi,
        githubService: githubService,
        dbValue: db,
      );
      log = FakeLogging();
      request = FakeHttpRequest();
      tester = ApiRequestHandlerTester(request: request, context: authContext);
      handler = OverrideGitHubBuildStatus(
        config,
        auth,
        datastoreProvider: (DatastoreDB db) => DatastoreService(config.db, 5),
        loggingProvider: () => log,
      );

      githubPullRequests = <int>[];
      githubService.listPullRequestsBranch = (String branch) {
        return pullRequestList(branch);
      };

      repositoriesService = MockRepositoriesService();
      when(githubService.github.repositories).thenReturn(repositoriesService);
    });

    Future<dynamic> decodeHandlerBody() async {
      final Body body = await tester.get(handler);
      return await utf8.decoder
        .bind(body.serialize())
        // .transform(json.decoder)
        .single;
    }

    test('get works', () async {
      when(jobsResourceApi.query(any, 'flutter-dashboard')).thenAnswer((_) async {
        return QueryResponse()..rows = <TableRow>[
          TableRow()..f = <TableCell>[
            TableCell()..v = 'flutter/flutter',
            TableCell()..v = 'test@test.com',
            TableCell()..v = 'Testing 123',
            TableCell()..v = 'false',
            TableCell()..v = timeStamp.toString(),
          ],
          TableRow()..f = <TableCell>[
            TableCell()..v = 'flutter/engine',
            TableCell()..v = 'test@test.com',
            TableCell()..v = 'Testing 123',
            TableCell()..v = 'false',
            TableCell()..v = timeStamp.toString(),
          ],
        ];
      });
      // print(await decodeHandlerBody());
      print(await decodeHandlerBody());
      // expect(response.single, overrides.toJson());
    });
//[{"repository":"flutter/flutter","user":"test@test.com","reason":"Testing 123","closed":false,"timestamp":1600114135054},{"repository":"flutter/engine","user":"test@test.com","reason":"Testing 123","closed":false,"timestamp":1600114135054}]

    test('post forbids unauthenticated users', () async {
      await expectLater(
        () async => await tester.post(handler),
        throwsA(isA<Forbidden>()),
      );
    });

    test('post does nothing if the status is not changing', () async {
      authContext.email = 'user@google.com';
      final GithubTreeStatusOverride overrides = GithubTreeStatusOverride(
        key: db.emptyKey.append(GithubTreeStatusOverride, id: 0),
        closed: false,
        reason: 'testing1',
        repository: 'flutter/flutter',
        user: 'user@google.com',
      );
      db.values[overrides.key] = overrides;
      tester.requestData = const OverrideGitHubBuildStatusRequest(
        repository: 'flutter/flutter',
        closed: false,
        reason: 'just a test',
      ).toJson();

      final Body body = await tester.post(handler);
      expect(body, same(Body.empty));
      expect(db.values.values.first, overrides);
      expect(overrides.closed, false);
    });

    test('post updates datastore and github if status changes', () async {
      githubPullRequests = <int>[1, 2, 3];
      authContext.email = 'user@google.com';
      final GithubTreeStatusOverride overrides = GithubTreeStatusOverride(
        key: db.emptyKey.append(GithubTreeStatusOverride, id: 0),
        closed: false,
        reason: 'testing1',
        repository: 'flutter/flutter',
        user: 'user@google.com',
      );
      db.values[overrides.key] = overrides;
      tester.requestData = const OverrideGitHubBuildStatusRequest(
        repository: 'flutter/flutter',
        closed: true,
        reason: 'just a test',
      ).toJson();

      final Body body = await tester.post(handler);
      expect(body, same(Body.empty));
      expect(db.values.values.first, overrides);
      expect(overrides.closed, true);
      expect(overrides.reason, 'just a test');

      final List<dynamic> calls = verify(repositoriesService.createStatus(any, any, captureAny)).captured;
      expect(calls.length, 3);
      expect(
        calls.first.toJson(),
        jsonDecode(
          '{"state":"failure","target_url":"https://flutter-dashboard.appspot.com/api/override-github-build-status","description":"just a test","context":"tree-status"}',
        ),
      );
      expect(log.records.first.level, LogLevel.DEBUG);
      expect(log.records.first.message, 'Updating tree status of flutter/flutter#1 (closed = true)');
      expect(log.records.length, 3);
    });

    test('logs an error when github throws', () async {
      when(repositoriesService.createStatus(any, any, captureAny)).thenThrow('bad news');

      githubPullRequests = <int>[1, 2, 3];
      authContext.email = 'user@google.com';
      final GithubTreeStatusOverride overrides = GithubTreeStatusOverride(
        key: db.emptyKey.append(GithubTreeStatusOverride, id: 0),
        closed: false,
        reason: 'testing1',
        repository: 'flutter/flutter',
        user: 'user@google.com',
      );
      db.values[overrides.key] = overrides;
      tester.requestData = const OverrideGitHubBuildStatusRequest(
        repository: 'flutter/flutter',
        closed: true,
        reason: 'just a test',
      ).toJson();

      final Body body = await tester.post(handler);
      expect(body, same(Body.empty));
      expect(db.values.values.first, overrides);
      expect(overrides.closed, true);
      expect(overrides.reason, 'just a test');

      final List<dynamic> calls = verify(repositoriesService.createStatus(any, any, captureAny)).captured;
      expect(calls.length, 3);
      expect(
        calls.first.toJson(),
        jsonDecode(
          '{"state":"failure","target_url":"https://flutter-dashboard.appspot.com/api/override-github-build-status","description":"just a test","context":"tree-status"}',
        ),
      );
      expect(log.records.first.level, LogLevel.DEBUG);
      expect(log.records.first.message, 'Updating tree status of flutter/flutter#1 (closed = true)');
      expect(log.records[1].level, LogLevel.ERROR);
      expect(log.records[1].message, 'Failed to post status update to flutter/flutter#1: bad news');
      expect(log.records.length, 6);
    });
  });
}

class MockJobsResourceApi extends Mock implements JobsResourceApi {}

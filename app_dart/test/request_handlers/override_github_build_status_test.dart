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
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/bigquery/fake_tabledata_resource.dart';
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
    FakeTabledataResourceApi tabledataResourceApi;
    List<int> githubPullRequests;
    MockRepositoriesService repositoriesService;

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
      clientContext = FakeClientContext();
      authContext = FakeAuthenticatedContext(clientContext: clientContext);
      auth = FakeAuthenticationProvider(clientContext: clientContext);
      final FakeGithubService githubService = FakeGithubService();
      db = FakeDatastoreDB();
      config = FakeConfig(tabledataResourceApi: tabledataResourceApi, githubService: githubService, dbValue: db);
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

    Future<T> decodeHandlerBody<T>() async {
      final Body body = await tester.get(handler);
      return await utf8.decoder.bind(body.serialize()).transform(json.decoder).single as T;
    }

    test('get works', () async {
      final GithubTreeStatusOverride overrides = GithubTreeStatusOverride(
        key: db.emptyKey.append(GithubTreeStatusOverride, id: 0),
        closed: false,
        reason: 'testing1',
        repository: 'flutter/flutter',
        user: 'test@flutter.com',
      );
      db.values[overrides.key] = overrides;
      final List<dynamic> response = await decodeHandlerBody<List<dynamic>>();
      expect(response.single, overrides.toJson());
    });

    test('put forbids unauthenticated users', () async {
      await expectLater(
        () async => await tester.put(handler),
        throwsA(isA<Forbidden>()),
      );
    });

    test('put does nothing if the status is not changing', () async {
      authContext.email = 'user@google.com';
      final GithubTreeStatusOverride overrides = GithubTreeStatusOverride(
        key: db.emptyKey.append(GithubTreeStatusOverride, id: 0),
        closed: false,
        reason: 'testing1',
        repository: 'flutter/flutter',
        user: 'user@google.com',
      );
      db.values[overrides.key] = overrides;
      tester.requestData = <String, dynamic>{
        OverrideGitHubBuildStatus.closedKeyName: false,
        OverrideGitHubBuildStatus.repositoryKeyName: 'flutter/flutter',
        OverrideGitHubBuildStatus.reasonKeyName: 'just a test',
      };

      final Body body = await tester.put(handler);
      expect(body, same(Body.empty));
      expect(db.values.values.first, overrides);
      expect(overrides.closed, false);
    });

    test('put updates datastore and github if status changes', () async {
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
      tester.requestData = <String, dynamic>{
        OverrideGitHubBuildStatus.closedKeyName: true,
        OverrideGitHubBuildStatus.repositoryKeyName: 'flutter/flutter',
        OverrideGitHubBuildStatus.reasonKeyName: 'just a test',
      };

      final Body body = await tester.put(handler);
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

    test('put updates datastore and github if forced', () async {
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
      tester.requestData = <String, dynamic>{
        OverrideGitHubBuildStatus.closedKeyName: false,
        OverrideGitHubBuildStatus.repositoryKeyName: 'flutter/flutter',
        OverrideGitHubBuildStatus.reasonKeyName: 'just a test',
        OverrideGitHubBuildStatus.forceKeyName: true,
      };

      final Body body = await tester.put(handler);
      expect(body, same(Body.empty));
      expect(db.values.values.first, overrides);
      expect(overrides.closed, false);
      expect(overrides.reason, 'just a test');

      final List<dynamic> calls = verify(repositoriesService.createStatus(any, any, captureAny)).captured;
      expect(calls.length, 3);
      expect(
        calls.first.toJson(),
        jsonDecode(
          '{"state":"success","target_url":"https://flutter-dashboard.appspot.com/api/override-github-build-status","description":"just a test","context":"tree-status"}',
        ),
      );
      expect(log.records.first.level, LogLevel.DEBUG);
      expect(log.records.first.message, 'Updating tree status of flutter/flutter#1 (closed = false)');
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
      tester.requestData = <String, dynamic>{
        OverrideGitHubBuildStatus.closedKeyName: true,
        OverrideGitHubBuildStatus.repositoryKeyName: 'flutter/flutter',
        OverrideGitHubBuildStatus.reasonKeyName: 'just a test',
      };

      final Body body = await tester.put(handler);
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

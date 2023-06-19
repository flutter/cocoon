// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/appengine/stage.dart';
import 'package:cocoon_service/src/request_handlers/get_status.dart';
import 'package:cocoon_service/src/request_handling/body.dart';
import 'package:cocoon_service/src/service/build_status_provider.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:gcloud/db.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/request_handling/fake_http.dart';
import '../src/request_handling/request_handler_tester.dart';
import '../src/service/fake_build_status_provider.dart';

void main() {
  group('GetStatus', () {
    late FakeConfig config;
    FakeClientContext clientContext;
    FakeKeyHelper keyHelper;
    FakeBuildStatusService buildStatusService;
    late RequestHandlerTester tester;
    late GetStatus handler;

    late Commit commit1;
    late Commit commit2;

    Future<T?> decodeHandlerBody<T>() async {
      final Body body = await tester.get(handler);
      return await utf8.decoder.bind(body.serialize() as Stream<List<int>>).transform(json.decoder).single as T?;
    }

    setUp(() {
      clientContext = FakeClientContext();
      keyHelper = FakeKeyHelper(applicationContext: clientContext.applicationContext);
      tester = RequestHandlerTester();
      config = FakeConfig(keyHelperValue: keyHelper);
      buildStatusService = FakeBuildStatusService(commitStatuses: <CommitStatus>[]);
      handler = GetStatus(
        config: config,
        datastoreProvider: (DatastoreDB db) => DatastoreService(config.db, 5),
        buildStatusProvider: (_) => buildStatusService,
      );
      commit1 = Commit(
        key: config.db.emptyKey.append(Commit, id: 'flutter/flutter/ea28a9c34dc701de891eaf74503ca4717019f829'),
        repository: 'flutter/flutter',
        sha: 'ea28a9c34dc701de891eaf74503ca4717019f829',
        timestamp: 3,
        message: 'test message 1',
        branch: 'master',
      );
      commit2 = Commit(
        key: config.db.emptyKey.append(Commit, id: 'flutter/flutter/d5b0b3c8d1c5fd89302089077ccabbcfaae045e4'),
        repository: 'flutter/flutter',
        sha: 'd5b0b3c8d1c5fd89302089077ccabbcfaae045e4',
        timestamp: 1,
        message: 'test message 2',
        branch: 'master',
      );
    });

    test('no statuses', () async {
      final Map<String, dynamic> result = (await decodeHandlerBody())!;
      expect(result['Statuses'], isEmpty);
    });

    test('reports statuses without input commit key', () async {
      config.db.values[commit1.key] = commit1;
      config.db.values[commit2.key] = commit2;
      buildStatusService = FakeBuildStatusService(
        commitStatuses: <CommitStatus>[CommitStatus(commit1, const <Stage>[]), CommitStatus(commit2, const <Stage>[])],
      );
      handler = GetStatus(
        config: config,
        datastoreProvider: (DatastoreDB db) => DatastoreService(config.db, 5),
        buildStatusProvider: (_) => buildStatusService,
      );

      final Map<String, dynamic> result = (await decodeHandlerBody())!;

      expect(result['Statuses'].length, 2);
    });

    test('reports statuses with input commit key', () async {
      final Commit commit1 = Commit(
        key: config.db.emptyKey.append(Commit, id: 'flutter/flutter/ea28a9c34dc701de891eaf74503ca4717019f829'),
        repository: 'flutter/flutter',
        sha: 'ea28a9c34dc701de891eaf74503ca4717019f829',
        timestamp: 3,
        message: 'test message 1',
        branch: 'master',
      );
      final Commit commit2 = Commit(
        key: config.db.emptyKey.append(Commit, id: 'flutter/flutter/d5b0b3c8d1c5fd89302089077ccabbcfaae045e4'),
        repository: 'flutter/flutter',
        sha: 'd5b0b3c8d1c5fd89302089077ccabbcfaae045e4',
        timestamp: 1,
        message: 'test message 2',
        branch: 'master',
      );
      config.db.values[commit1.key] = commit1;
      config.db.values[commit2.key] = commit2;
      buildStatusService = FakeBuildStatusService(
        commitStatuses: <CommitStatus>[CommitStatus(commit1, const <Stage>[]), CommitStatus(commit2, const <Stage>[])],
      );
      handler = GetStatus(
        config: config,
        datastoreProvider: (DatastoreDB db) => DatastoreService(config.db, 5),
        buildStatusProvider: (_) => buildStatusService,
      );

      const String expectedLastCommitKeyEncoded =
          'ahNzfmZsdXR0ZXItZGFzaGJvYXJkckcLEglDaGVja2xpc3QiOGZsdXR0ZXIvZmx1dHRlci9lYTI4YTljMzRkYzcwMWRlODkxZWFmNzQ1MDNjYTQ3MTcwMTlmODI5DA';

      tester.request = FakeHttpRequest(
        queryParametersValue: <String, String>{
          GetStatus.kLastCommitKeyParam: expectedLastCommitKeyEncoded,
        },
      );
      final Map<String, dynamic> result = (await decodeHandlerBody())!;

      expect(result['Statuses'].first, <String, dynamic>{
        'Checklist': <String, dynamic>{
          'Key':
              'ahFmbHV0dGVyLWRhc2hib2FyZHJHCxIJQ2hlY2tsaXN0IjhmbHV0dGVyL2ZsdXR0ZXIvZDViMGIzYzhkMWM1ZmQ4OTMwMjA4OTA3N2NjYWJiY2ZhYWUwNDVlNAyiAQlbZGVmYXVsdF0',
          'Checklist': <String, dynamic>{
            'FlutterRepositoryPath': 'flutter/flutter',
            'CreateTimestamp': 1,
            'Commit': <String, dynamic>{
              'Sha': 'd5b0b3c8d1c5fd89302089077ccabbcfaae045e4',
              'Message': 'test message 2',
              'Author': <String, dynamic>{'Login': null, 'avatar_url': null},
            },
            'Branch': 'master',
          },
        },
        'Stages': <String>[],
      });
    });

    test('reports statuses with input branch', () async {
      commit2.branch = 'flutter-1.1-candidate.1';
      config.db.values[commit1.key] = commit1;
      config.db.values[commit2.key] = commit2;
      buildStatusService = FakeBuildStatusService(
        commitStatuses: <CommitStatus>[CommitStatus(commit1, const <Stage>[]), CommitStatus(commit2, const <Stage>[])],
      );
      handler = GetStatus(
        config: config,
        datastoreProvider: (DatastoreDB db) => DatastoreService(config.db, 5),
        buildStatusProvider: (_) => buildStatusService,
      );

      const String branch = 'flutter-1.1-candidate.1';

      expect(config.db.values.length, 2);

      tester.request = FakeHttpRequest(
        queryParametersValue: <String, String>{
          GetStatus.kBranchParam: branch,
        },
      );
      final Map<String, dynamic> result = (await decodeHandlerBody())!;

      expect(result['Statuses'].length, 1);
      expect(result['Statuses'].first, <String, dynamic>{
        'Checklist': <String, dynamic>{
          'Key':
              'ahFmbHV0dGVyLWRhc2hib2FyZHJHCxIJQ2hlY2tsaXN0IjhmbHV0dGVyL2ZsdXR0ZXIvZDViMGIzYzhkMWM1ZmQ4OTMwMjA4OTA3N2NjYWJiY2ZhYWUwNDVlNAyiAQlbZGVmYXVsdF0',
          'Checklist': <String, dynamic>{
            'FlutterRepositoryPath': 'flutter/flutter',
            'CreateTimestamp': 1,
            'Commit': <String, dynamic>{
              'Sha': 'd5b0b3c8d1c5fd89302089077ccabbcfaae045e4',
              'Message': 'test message 2',
              'Author': <String, dynamic>{'Login': null, 'avatar_url': null},
            },
            'Branch': 'flutter-1.1-candidate.1',
          },
        },
        'Stages': <String>[],
      });
    });
  });
}

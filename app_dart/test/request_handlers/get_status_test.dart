// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_service/src/model/appengine/agent.dart';
import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/appengine/stage.dart';
import 'package:cocoon_service/src/request_handlers/get_status.dart';
import 'package:cocoon_service/src/request_handling/body.dart';
import 'package:cocoon_service/src/service/build_status_provider.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_cocoon_config.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/request_handling/fake_http.dart';
import '../src/request_handling/request_handler_tester.dart';
import '../src/service/fake_build_status_provider.dart';

void main() {
  group('GetStatus', () {
    FakeConfig config;
    FakeClientContext clientContext;
    FakeKeyHelper keyHelper;
    FakeBuildStatusProvider buildStatusProvider;
    RequestHandlerTester tester;
    GetStatus handler;

    Future<Object> decodeHandlerBody() async {
      final Body body = await tester.get(handler);
      return utf8.decoder.bind(body.serialize()).transform(json.decoder).single;
    }

    setUp(() {
      clientContext = FakeClientContext();
      keyHelper =
          FakeKeyHelper(applicationContext: clientContext.applicationContext);
      tester = RequestHandlerTester();
      config = FakeConfig(keyHelperValue: keyHelper);
      buildStatusProvider =
          FakeBuildStatusProvider(commitStatuses: <CommitStatus>[]);
      handler = GetStatus(
        config,
        datastoreProvider: () => DatastoreService(db: config.db),
        buildStatusProvider: buildStatusProvider,
      );
    });

    test('no statuses or agents', () async {
      final Map<String, dynamic> result = await decodeHandlerBody();
      expect(result['Statuses'], isEmpty);
      expect(result['AgentStatuses'], isEmpty);
    });

    test('reports agents', () async {
      final Agent linux1 = Agent(agentId: 'linux1');
      final Agent mac1 = Agent(agentId: 'mac1');
      final Agent linux100 = Agent(agentId: 'linux100');
      final Agent linux5 = Agent(agentId: 'linux5');
      final Agent windows1 = Agent(agentId: 'windows1', isHidden: true);

      final List<Agent> reportedAgents = <Agent>[
        linux1,
        mac1,
        linux100,
        linux5,
        windows1,
      ];

      config.db.addOnQuery<Agent>((Iterable<Agent> agents) => reportedAgents);
      final Map<String, dynamic> result = await decodeHandlerBody();

      expect(result['Statuses'], isEmpty);

      final List<dynamic> expectedOrderedAgents = <dynamic>[
        linux1.toJson(),
        linux5.toJson(),
        linux100.toJson(),
        mac1.toJson(),
      ];

      expect(result['AgentStatuses'], equals(expectedOrderedAgents));
    });

    test('reports statuses without input commit key', () async {
      final Commit commit1 = Commit(
          key: config.db.emptyKey.append(Commit,
              id: 'flutter/flutter/ea28a9c34dc701de891eaf74503ca4717019f829'),
          timestamp: 3);
      final Commit commit2 = Commit(
          key: config.db.emptyKey.append(Commit,
              id: 'flutter/flutter/d5b0b3c8d1c5fd89302089077ccabbcfaae045e4'),
          timestamp: 1);
      config.db.values[commit1.key] = commit1;
      config.db.values[commit2.key] = commit2;
      buildStatusProvider = FakeBuildStatusProvider(
          commitStatuses: <CommitStatus>[
            CommitStatus(commit1, const <Stage>[]),
            CommitStatus(commit2, const <Stage>[])
          ]);
      handler = GetStatus(
        config,
        datastoreProvider: () => DatastoreService(db: config.db),
        buildStatusProvider: buildStatusProvider,
      );

      final Map<String, dynamic> result = await decodeHandlerBody();

      expect(result['Statuses'].length, 2);
    });

    test('reports statuses with input commit key', () async {
      final Commit commit1 = Commit(
          key: config.db.emptyKey.append(Commit,
              id: 'flutter/flutter/ea28a9c34dc701de891eaf74503ca4717019f829'),
          timestamp: 3);
      final Commit commit2 = Commit(
          key: config.db.emptyKey.append(Commit,
              id: 'flutter/flutter/d5b0b3c8d1c5fd89302089077ccabbcfaae045e4'),
          timestamp: 1);
      config.db.values[commit1.key] = commit1;
      config.db.values[commit2.key] = commit2;
      buildStatusProvider = FakeBuildStatusProvider(
          commitStatuses: <CommitStatus>[
            CommitStatus(commit1, const <Stage>[]),
            CommitStatus(commit2, const <Stage>[])
          ]);
      handler = GetStatus(
        config,
        datastoreProvider: () => DatastoreService(db: config.db),
        buildStatusProvider: buildStatusProvider,
      );

      const String expectedLastCommitKeyEncoded =
          'ahNzfmZsdXR0ZXItZGFzaGJvYXJkckcLEglDaGVja2xpc3QiOGZsdXR0ZXIvZmx1dHRlci9lYTI4YTljMzRkYzcwMWRlODkxZWFmNzQ1MDNjYTQ3MTcwMTlmODI5DA';

      tester.request = FakeHttpRequest(queryParametersValue: <String, String>{
        GetStatus.lastCommitKeyParam: expectedLastCommitKeyEncoded,
      });
      final Map<String, dynamic> result = await decodeHandlerBody();
      //final Map<String, dynamic> result

      expect(result['Statuses'].first, <String, dynamic>{
        'Checklist': <String, dynamic>{
          'Key': '',
          'Checklist': <String, dynamic>{
            'FlutterRepositoryPath': null,
            'CreateTimestamp': 1,
            'Commit': <String, dynamic>{
              'Sha': null,
              'Author': <String, dynamic>{'Login': null, 'avatar_url': null}
            }
          }
        },
        'Stages': <String>[]
      });
    });
  });
}

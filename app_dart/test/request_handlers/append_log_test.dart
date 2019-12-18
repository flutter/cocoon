// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:gcloud/db.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'package:cocoon_service/src/request_handlers/append_log.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:cocoon_service/src/service/stackdriver_logger.dart';
import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/appengine/log_chunk.dart';
import 'package:cocoon_service/src/model/appengine/task.dart';

import '../src/datastore/fake_cocoon_config.dart';
import '../src/datastore/fake_datastore.dart';
import '../src/request_handling/api_request_handler_tester.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/request_handling/fake_http.dart';

void main() {
  group('AppendLog', () {
    FakeConfig config;
    AppendLog handler;
    ApiRequestHandlerTester tester;
    FakeDatastoreDB datastoreDB;
    MockStackdriverLoggerService mockStackdriverLoggerService;

    const String logData = '''
Deleting build/ directories, if any.
2019-12-05T12:55:27.221776: Observatory listening on http://127.0.0.1:20000/
2019-12-05T12:55:28.339859: Running task.
2019-12-05T12:55:28.340711: 

══════════════════╡ ••• Checking running Dart processes ••• ╞═══════════════════

2019-12-05T12:55:28.473920: RunningProcesses{pid: 497, commandLine: dart bin/agent.dart ci -c''';

    const String expectedTaskKeyEncoded =
        'ag9zfnR2b2xrZXJ0LXRlc3RyWAsSCUNoZWNrbGlzdCI4Zmx1dHRlci9mbHV0dGVyLzdkMDMzNzE2MTBjMDc5NTNhNWRlZjUwZDUwMDA0NTk0MWRlNTE2YjgMCxIEVGFzaxiAgIDg5eGTCAw';

    setUp(() {
      tester = ApiRequestHandlerTester();
      datastoreDB = FakeDatastoreDB();
      config = FakeConfig(
        dbValue: datastoreDB,
      );

      mockStackdriverLoggerService = MockStackdriverLoggerService();
      handler = AppendLog(
        config,
        FakeAuthenticationProvider(),
        stackdriverLogger: mockStackdriverLoggerService,
        requestBodyValue: Uint8List.fromList(logData.codeUnits),
      );
    });

    tearDown(() {
      clearInteractions(mockStackdriverLoggerService);
    });

    test('bad request when owner key not given', () async {
      expect(() => tester.post(handler), throwsA(isA<BadRequestException>()));
    });

    test('internal server error when task key does not exist', () async {
      tester.request = FakeHttpRequest(queryParametersValue: <String, String>{
        AppendLog.ownerKeyParam: expectedTaskKeyEncoded,
      });
      expect(() => tester.post(handler), throwsA(isA<InternalServerError>()));
    });

    test('adds log chunk to datastore', () async {
      final Commit commit = Commit(
          key: datastoreDB.emptyKey.append(Commit,
              id: 'flutter/flutter/7d03371610c07953a5def50d500045941de516b8'));
      final Task task = Task(
          key: commit.key.append(Task, id: 4590522719010816),
          commitKey: commit.key,
          requiredCapabilities: <String>['ios']);
      datastoreDB.values[task.key] = task;

      tester.request = FakeHttpRequest(queryParametersValue: <String, String>{
        AppendLog.ownerKeyParam: expectedTaskKeyEncoded,
      });

      // Only task should exist in the db
      expect(datastoreDB.values.keys.length, 1);

      await tester.post(handler);

      // Now task and a log chunk should exist
      expect(datastoreDB.values.keys.length, 2);

      // To get the log chunk key, remove the known task key
      final List<Key> dbKeys = datastoreDB.values.keys.toList();
      dbKeys.remove(task.key);
      final Key logChunkKey = dbKeys[0];

      final LogChunk logChunk =
          await datastoreDB.lookupValue<LogChunk>(logChunkKey);
      expect(logChunk, isNotNull);
    });

    test('pushes log data to stackdriver for writing', () async {
      verifyNever(mockStackdriverLoggerService.writeLines(any, any));
      await handler.writeToStackdriver('log123');

      /// verify call matches the expected
      final List<String> expectedLines = <String>[
        'Deleting build/ directories, if any.',
        '2019-12-05T12:55:27.221776: Observatory listening on http://127.0.0.1:20000/',
        '2019-12-05T12:55:28.339859: Running task.',
        '2019-12-05T12:55:28.340711: ',
        '',
        'PPPPPPPPPPPPPPPPPPa """ Checking running Dart processes """ ^PPPPPPPPPPPPPPPPPPP', // utf8 magic :)
        '',
        '2019-12-05T12:55:28.473920: RunningProcesses{pid: 497, commandLine: dart bin/agent.dart ci -c',
      ];
      verify(mockStackdriverLoggerService.writeLines('log123', expectedLines))
          .called(1);
    });
  });
}

/// Mock [StackdriverLoggerService] for testing interactions.
class MockStackdriverLoggerService extends Mock
    implements StackdriverLoggerService {}

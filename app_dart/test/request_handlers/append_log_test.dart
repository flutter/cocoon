// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'package:cocoon_service/src/request_handlers/append_log.dart';
import 'package:cocoon_service/src/service/stackdriver_logger.dart';

import '../src/datastore/fake_cocoon_config.dart';
import '../src/request_handling/fake_authentication.dart';

void main() {
  group('AppendLog', () {
    FakeConfig config;
    AppendLog handler;
    MockStackdriverLoggerService mockStackdriverLoggerService;

    const String logData = '''
Deleting build/ directories, if any.
2019-12-05T12:55:27.221776: Observatory listening on http://127.0.0.1:20000/
2019-12-05T12:55:28.339859: Running task.
2019-12-05T12:55:28.340711: 

══════════════════╡ ••• Checking running Dart processes ••• ╞═══════════════════

2019-12-05T12:55:28.473920: RunningProcesses{pid: 497, commandLine: dart bin/agent.dart ci -c''';

    setUp(() {
      config = FakeConfig();

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

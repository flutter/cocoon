// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_common/guard_status.dart';
import 'package:cocoon_common/rpc_model.dart';
import 'package:cocoon_common/task_status.dart';
import 'package:fake_async/fake_async.dart';
import 'package:github/github.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';
import 'package:wait_for_tests/wait_for_tests.dart';

class MockClient extends http.BaseClient {
  final Future<http.StreamedResponse> Function(http.BaseRequest) _sendHandler;

  MockClient(this._sendHandler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _sendHandler(request);
  }
}

http.StreamedResponse _stringResponse(String body, int status) {
  return http.StreamedResponse(
    Stream.value(utf8.encode(body)),
    status,
    headers: {'content-type': 'application/json'},
  );
}

/// Helper to create a strongly typed [PresubmitGuardResponse] for testing [evaluateTests].
PresubmitGuardResponse _createResponse({
  required Map<String, TaskStatus> jobs,
  GuardStatus guardStatus = GuardStatus.inProgress,
}) {
  return PresubmitGuardResponse(
    prNum: 1,
    checkRunId: 1,
    author: 'author',
    guardStatus: guardStatus,
    stages: [PresubmitGuardStage(name: 'stage', createdAt: 1234, jobs: jobs)],
  );
}

/// Helper to create a valid JSON response string for testing [waitForTests].
String _validResponseJson({
  required Map<String, String> jobs,
  String guardStatus = 'In Progress',
}) {
  return jsonEncode({
    'pr_num': 1,
    'check_run_id': 1,
    'author': 'author',
    'guard_status': guardStatus,
    'stages': [
      {'name': 'stage', 'created_at': 1234, 'jobs': jobs},
    ],
  });
}

void main() {
  group('evaluateTests', () {
    test('succeeds when all required tests succeed', () {
      final response = _createResponse(
        jobs: {
          'Linux windows_host_engine': TaskStatus.succeeded,
          'Mac mac_ios_engine': TaskStatus.neutral,
          'Linux linux_fuchsia': TaskStatus.skipped,
        },
      );
      final requiredTests = [
        'Linux windows_host_engine',
        'Mac mac_ios_engine',
        'Linux linux_fuchsia',
      ];
      final result = evaluateTests(
        response: response,
        requiredTests: requiredTests,
      );

      expect(result.allSucceeded, isTrue);
      expect(result.anyFailed, isFalse);
      expect(result.summaries, hasLength(3));
      expect(result.summaries[0].status, TaskStatus.succeeded);
      expect(result.summaries[1].status, TaskStatus.neutral);
      expect(result.summaries[2].status, TaskStatus.skipped);
    });

    test('fails when any required test fails', () {
      final response = _createResponse(
        jobs: {
          'Linux windows_host_engine': TaskStatus.succeeded,
          'Mac mac_ios_engine': TaskStatus.failed,
        },
      );
      final requiredTests = ['Linux windows_host_engine', 'Mac mac_ios_engine'];
      final result = evaluateTests(
        response: response,
        requiredTests: requiredTests,
      );

      expect(result.allSucceeded, isFalse);
      expect(result.anyFailed, isTrue);
      expect(result.summaries[1].status, TaskStatus.failed);
    });

    test('is pending when some tests are in progress or waiting', () {
      final response = _createResponse(
        jobs: {
          'Linux windows_host_engine': TaskStatus.succeeded,
          'Mac mac_ios_engine': TaskStatus.inProgress,
        },
      );
      final requiredTests = ['Linux windows_host_engine', 'Mac mac_ios_engine'];
      final result = evaluateTests(
        response: response,
        requiredTests: requiredTests,
      );

      expect(result.allSucceeded, isFalse);
      expect(result.anyFailed, isFalse);
      expect(result.summaries[1].status, TaskStatus.inProgress);
    });

    test('treats missing required tests as waiting', () {
      final response = _createResponse(
        jobs: {'Linux windows_host_engine': TaskStatus.succeeded},
      );
      final requiredTests = ['Linux windows_host_engine', 'Mac mac_ios_engine'];
      final result = evaluateTests(
        response: response,
        requiredTests: requiredTests,
      );

      expect(result.allSucceeded, isFalse);
      expect(result.anyFailed, isFalse);
      expect(result.summaries[1].status, TaskStatus.waitingForBackfill);
    });

    test('is case-insensitive and trims whitespace on job name matching', () {
      final response = _createResponse(
        jobs: {'  Linux windows_host_engine  ': TaskStatus.succeeded},
      );
      final requiredTests = ['linux windows_host_engine'];
      final result = evaluateTests(
        response: response,
        requiredTests: requiredTests,
      );

      expect(result.allSucceeded, isTrue);
      expect(result.anyFailed, isFalse);
    });

    test('correctly evaluates all status enum values', () {
      final statusMap = {
        TaskStatus.succeeded: true,
        TaskStatus.neutral: true,
        TaskStatus.skipped: true,
        TaskStatus.failed: false,
        TaskStatus.infraFailure: false,
        TaskStatus.cancelled: false,
        TaskStatus.inProgress: false,
        TaskStatus.waitingForBackfill: false,
      };

      for (final MapEntry(key: status, value: isSuccess) in statusMap.entries) {
        final response = _createResponse(jobs: {'test_job': status});
        final result = evaluateTests(
          response: response,
          requiredTests: ['test_job'],
        );
        expect(
          result.summaries[0].status,
          status,
          reason: 'Failed to verify status $status',
        );
        expect(
          result.allSucceeded,
          isSuccess,
          reason: 'Expected allSucceeded to be $isSuccess for status $status',
        );
      }
    });

    test(
      'isGuardFailed causes anyFailed to be true even when requiredTests is provided and has no failed tests',
      () {
        final response = _createResponse(
          guardStatus: GuardStatus.failed,
          jobs: {'Linux windows_host_engine': TaskStatus.succeeded},
        );
        final requiredTests = ['Linux windows_host_engine'];
        final result = evaluateTests(
          response: response,
          requiredTests: requiredTests,
        );

        expect(result.allSucceeded, isTrue);
        expect(result.anyFailed, isTrue);
      },
    );
  });

  group('waitForTests with fake_async', () {
    test('returns immediately on success on first check', () {
      final mockClient = MockClient((request) async {
        return _stringResponse(
          _validResponseJson(jobs: {'Linux windows_host_engine': 'Succeeded'}),
          200,
        );
      });

      fakeAsync((async) {
        var completed = false;
        var successResult = false;

        waitForTests(
          sha: 'd100ca3882520e04129ff2a5c09372ecec3b3860',
          slug: RepositorySlug('flutter', 'flutter'),
          requiredTests: const ['Linux windows_host_engine'],
          waitInterval: const Duration(seconds: 10),
          client: mockClient,
          log: (_) {},
        ).then((res) {
          completed = true;
          successResult = res;
        });

        async.elapse(const Duration(milliseconds: 10));
        expect(completed, isTrue);
        expect(successResult, isTrue);
      });
    });

    test('returns immediately on failure on first check', () {
      final mockClient = MockClient((request) async {
        return _stringResponse(
          _validResponseJson(jobs: {'Linux windows_host_engine': 'Failed'}),
          200,
        );
      });

      fakeAsync((async) {
        var completed = false;
        var successResult = true;

        waitForTests(
          sha: 'd100ca3882520e04129ff2a5c09372ecec3b3860',
          slug: RepositorySlug('flutter', 'flutter'),
          requiredTests: const ['Linux windows_host_engine'],
          waitInterval: const Duration(seconds: 10),
          client: mockClient,
          log: (_) {},
        ).then((res) {
          completed = true;
          successResult = res;
        });

        async.elapse(const Duration(milliseconds: 10));
        expect(completed, isTrue);
        expect(successResult, isFalse);
      });
    });

    test('polls multiple times and succeeds once tests complete', () {
      var callCount = 0;
      final mockClient = MockClient((request) async {
        callCount++;
        if (callCount == 1) {
          return _stringResponse(
            _validResponseJson(
              jobs: {'Linux windows_host_engine': 'In Progress'},
            ),
            200,
          );
        } else {
          return _stringResponse(
            _validResponseJson(
              jobs: {'Linux windows_host_engine': 'Succeeded'},
            ),
            200,
          );
        }
      });

      fakeAsync((async) {
        var completed = false;
        var successResult = false;

        waitForTests(
          sha: 'd100ca3882520e04129ff2a5c09372ecec3b3860',
          slug: RepositorySlug('flutter', 'flutter'),
          requiredTests: const ['Linux windows_host_engine'],
          waitInterval: const Duration(seconds: 30),
          client: mockClient,
          log: (_) {},
        ).then((res) {
          completed = true;
          successResult = res;
        });

        // First poll happens immediately
        async.elapse(const Duration(seconds: 2));
        expect(completed, isFalse);
        expect(callCount, 1);

        // elapse by interval to trigger second poll
        async.elapse(const Duration(seconds: 29));
        expect(completed, isTrue);
        expect(successResult, isTrue);
        expect(callCount, 2);
      });
    });

    test('polls multiple times and fails once a test fails', () {
      var callCount = 0;
      final mockClient = MockClient((request) async {
        callCount++;
        if (callCount == 1) {
          return _stringResponse(
            _validResponseJson(
              jobs: {'Linux windows_host_engine': 'In Progress'},
            ),
            200,
          );
        } else {
          return _stringResponse(
            _validResponseJson(jobs: {'Linux windows_host_engine': 'Failed'}),
            200,
          );
        }
      });

      fakeAsync((async) {
        var completed = false;
        var successResult = true;

        waitForTests(
          sha: 'd100ca3882520e04129ff2a5c09372ecec3b3860',
          slug: RepositorySlug('flutter', 'flutter'),
          requiredTests: const ['Linux windows_host_engine'],
          waitInterval: const Duration(seconds: 30),
          client: mockClient,
          log: (_) {},
        ).then((res) {
          completed = true;
          successResult = res;
        });

        async.elapse(const Duration(seconds: 2));
        expect(completed, isFalse);
        expect(callCount, 1);

        async.elapse(const Duration(seconds: 29));
        expect(completed, isTrue);
        expect(successResult, isFalse);
        expect(callCount, 2);
      });
    });

    test('times out after configured duration', () {
      final mockClient = MockClient((request) async {
        return _stringResponse(
          _validResponseJson(
            jobs: {'Linux windows_host_engine': 'In Progress'},
          ),
          200,
        );
      });

      fakeAsync((async) {
        var completed = false;
        var successResult = true;

        waitForTests(
          sha: 'd100ca3882520e04129ff2a5c09372ecec3b3860',
          slug: RepositorySlug('flutter', 'flutter'),
          requiredTests: const ['Linux windows_host_engine'],
          waitInterval: const Duration(seconds: 30),
          client: mockClient,
          log: (_) {},
          timeout: const Duration(seconds: 15),
        ).then((res) {
          completed = true;
          successResult = res;
        });

        async.elapse(const Duration(seconds: 35));

        expect(completed, isTrue);
        expect(successResult, isFalse);
      });
    });

    test('waits for all tests to succeed when requiredTests is empty', () {
      var callCount = 0;
      final mockClient = MockClient((request) async {
        callCount++;
        if (callCount == 1) {
          return _stringResponse(
            _validResponseJson(
              guardStatus: 'In Progress',
              jobs: {
                'Linux windows_host_engine': 'Succeeded',
                'Mac mac_ios_engine': 'In Progress',
              },
            ),
            200,
          );
        } else {
          return _stringResponse(
            _validResponseJson(
              guardStatus: 'Succeeded',
              jobs: {
                'Linux windows_host_engine': 'Succeeded',
                'Mac mac_ios_engine': 'Succeeded',
              },
            ),
            200,
          );
        }
      });

      fakeAsync((async) {
        var completed = false;
        var successResult = false;

        waitForTests(
          sha: 'd100ca3882520e04129ff2a5c09372ecec3b3860',
          slug: RepositorySlug('flutter', 'flutter'),
          requiredTests: const [],
          waitInterval: const Duration(seconds: 30),
          client: mockClient,
          log: (_) {},
        ).then((res) {
          completed = true;
          successResult = res;
        });

        // First poll
        async.elapse(const Duration(seconds: 2));
        expect(completed, isFalse);
        expect(callCount, 1);

        // Second poll (after wait interval)
        async.elapse(const Duration(seconds: 29));
        expect(completed, isTrue);
        expect(successResult, isTrue);
        expect(callCount, 2);
      });
    });

    test('fails immediately when any test fails in all-tests mode', () {
      final mockClient = MockClient((request) async {
        return _stringResponse(
          _validResponseJson(
            guardStatus: 'Failed',
            jobs: {
              'Linux windows_host_engine': 'Failed',
              'Mac mac_ios_engine': 'Succeeded',
            },
          ),
          200,
        );
      });

      fakeAsync((async) {
        var completed = false;
        var successResult = true;

        waitForTests(
          sha: 'd100ca3882520e04129ff2a5c09372ecec3b3860',
          slug: RepositorySlug('flutter', 'flutter'),
          requiredTests: const [],
          waitInterval: const Duration(seconds: 10),
          client: mockClient,
          log: (_) {},
        ).then((res) {
          completed = true;
          successResult = res;
        });

        async.elapse(const Duration(milliseconds: 10));
        expect(completed, isTrue);
        expect(successResult, isFalse);
      });
    });

    test('continues polling when HTTP client throws exception', () {
      var callCount = 0;
      final mockClient = MockClient((request) async {
        callCount++;
        if (callCount == 1) {
          throw Exception('Transient network error');
        } else {
          return _stringResponse(
            _validResponseJson(
              jobs: {'Linux windows_host_engine': 'Succeeded'},
            ),
            200,
          );
        }
      });

      fakeAsync((async) {
        var completed = false;
        var successResult = false;
        final logs = <String>[];

        waitForTests(
          sha: 'd100ca3882520e04129ff2a5c09372ecec3b3860',
          slug: RepositorySlug('flutter', 'flutter'),
          requiredTests: const ['Linux windows_host_engine'],
          waitInterval: const Duration(seconds: 30),
          client: mockClient,
          log: logs.add,
        ).then((res) {
          completed = true;
          successResult = res;
        });

        // First poll: fails with exception, caught, slept
        async.elapse(const Duration(seconds: 2));
        expect(completed, isFalse);
        expect(callCount, 1);
        expect(
          logs.any((l) => l.contains('Warning: Error calling Cocoon API')),
          isTrue,
        );

        // Advance to trigger second poll
        async.elapse(const Duration(seconds: 29));
        expect(completed, isTrue);
        expect(successResult, isTrue);
        expect(callCount, 2);
      });
    });

    test('continues polling when API returns non-200 status code', () {
      var callCount = 0;
      final mockClient = MockClient((request) async {
        callCount++;
        if (callCount == 1) {
          return _stringResponse('Gateway Timeout', 504);
        } else {
          return _stringResponse(
            _validResponseJson(
              jobs: {'Linux windows_host_engine': 'Succeeded'},
            ),
            200,
          );
        }
      });

      fakeAsync((async) {
        var completed = false;
        var successResult = false;
        final logs = <String>[];

        waitForTests(
          sha: 'd100ca3882520e04129ff2a5c09372ecec3b3860',
          slug: RepositorySlug('flutter', 'flutter'),
          requiredTests: const ['Linux windows_host_engine'],
          waitInterval: const Duration(seconds: 30),
          client: mockClient,
          log: logs.add,
        ).then((res) {
          completed = true;
          successResult = res;
        });

        // First poll: 504
        async.elapse(const Duration(seconds: 2));
        expect(completed, isFalse);
        expect(callCount, 1);
        expect(
          logs.any(
            (l) => l.contains('Warning: Cocoon API returned status code 504'),
          ),
          isTrue,
        );

        // Trigger second poll
        async.elapse(const Duration(seconds: 29));
        expect(completed, isTrue);
        expect(successResult, isTrue);
        expect(callCount, 2);
      });
    });

    test('continues polling when response is not valid JSON', () {
      var callCount = 0;
      final mockClient = MockClient((request) async {
        callCount++;
        if (callCount == 1) {
          return _stringResponse('not a json map', 200);
        } else {
          return _stringResponse(
            _validResponseJson(
              jobs: {'Linux windows_host_engine': 'Succeeded'},
            ),
            200,
          );
        }
      });

      fakeAsync((async) {
        var completed = false;
        var successResult = false;
        final logs = <String>[];

        waitForTests(
          sha: 'd100ca3882520e04129ff2a5c09372ecec3b3860',
          slug: RepositorySlug('flutter', 'flutter'),
          requiredTests: const ['Linux windows_host_engine'],
          waitInterval: const Duration(seconds: 30),
          client: mockClient,
          log: logs.add,
        ).then((res) {
          completed = true;
          successResult = res;
        });

        // First poll: invalid JSON
        async.elapse(const Duration(seconds: 2));
        expect(completed, isFalse);
        expect(callCount, 1);
        expect(
          logs.any(
            (l) => l.contains(
              'Warning: Failed to parse Cocoon API response as JSON',
            ),
          ),
          isTrue,
        );

        // Trigger second poll
        async.elapse(const Duration(seconds: 29));
        expect(completed, isTrue);
        expect(successResult, isTrue);
        expect(callCount, 2);
      });
    });

    test(
      'continues polling when response is valid JSON but fails to parse into PresubmitGuardResponse',
      () {
        var callCount = 0;
        final mockClient = MockClient((request) async {
          callCount++;
          if (callCount == 1) {
            return _stringResponse('{"invalid_field": true}', 200);
          } else {
            return _stringResponse(
              _validResponseJson(
                jobs: {'Linux windows_host_engine': 'Succeeded'},
              ),
              200,
            );
          }
        });

        fakeAsync((async) {
          var completed = false;
          var successResult = false;
          final logs = <String>[];

          waitForTests(
            sha: 'd100ca3882520e04129ff2a5c09372ecec3b3860',
            slug: RepositorySlug('flutter', 'flutter'),
            requiredTests: const ['Linux windows_host_engine'],
            waitInterval: const Duration(seconds: 30),
            client: mockClient,
            log: logs.add,
          ).then((res) {
            completed = true;
            successResult = res;
          });

          // First poll: valid JSON but fails to parse
          async.elapse(const Duration(seconds: 2));
          expect(completed, isFalse);
          expect(callCount, 1);
          expect(
            logs.any(
              (l) => l.contains(
                'Warning: Failed to parse JSON into PresubmitGuardResponse',
              ),
            ),
            isTrue,
          );

          // Trigger second poll
          async.elapse(const Duration(seconds: 29));
          expect(completed, isTrue);
          expect(successResult, isTrue);
          expect(callCount, 2);
        });
      },
    );

    test('clamps waitInterval to at least 30 seconds and logs warning', () {
      final mockClient = MockClient((request) async {
        return _stringResponse(
          _validResponseJson(jobs: {'Linux windows_host_engine': 'Succeeded'}),
          200,
        );
      });

      fakeAsync((async) {
        var completed = false;
        var successResult = false;
        final logs = <String>[];

        waitForTests(
          sha: 'd100ca3882520e04129ff2a5c09372ecec3b3860',
          slug: RepositorySlug('flutter', 'flutter'),
          requiredTests: const ['Linux windows_host_engine'],
          waitInterval: const Duration(seconds: 10),
          client: mockClient,
          log: logs.add,
        ).then((res) {
          completed = true;
          successResult = res;
        });

        async.elapse(const Duration(milliseconds: 10));
        expect(completed, isTrue);
        expect(successResult, isTrue);
        expect(
          logs.any(
            (l) => l.contains(
              'Warning: wait-interval must be between 30 and 600 seconds. Clamping from 10s to 30s.',
            ),
          ),
          isTrue,
        );
      });
    });

    test('clamps waitInterval to at most 600 seconds and logs warning', () {
      final mockClient = MockClient((request) async {
        return _stringResponse(
          _validResponseJson(jobs: {'Linux windows_host_engine': 'Succeeded'}),
          200,
        );
      });

      fakeAsync((async) {
        var completed = false;
        var successResult = false;
        final logs = <String>[];

        waitForTests(
          sha: 'd100ca3882520e04129ff2a5c09372ecec3b3860',
          slug: RepositorySlug('flutter', 'flutter'),
          requiredTests: const ['Linux windows_host_engine'],
          waitInterval: const Duration(seconds: 1000),
          client: mockClient,
          log: logs.add,
        ).then((res) {
          completed = true;
          successResult = res;
        });

        async.elapse(const Duration(milliseconds: 10));
        expect(completed, isTrue);
        expect(successResult, isTrue);
        expect(
          logs.any(
            (l) => l.contains(
              'Warning: wait-interval must be between 30 and 600 seconds. Clamping from 1000s to 600s.',
            ),
          ),
          isTrue,
        );
      });
    });

    test('fails immediately on non-transient 4xx client errors (e.g. 403)', () {
      final mockClient = MockClient((request) async {
        return _stringResponse('Neighborhood of the Beast', 466);
      });

      fakeAsync((async) {
        var completed = false;
        var successResult = true;
        final logs = <String>[];

        waitForTests(
          sha: 'd100ca3882520e04129ff2a5c09372ecec3b3860',
          slug: RepositorySlug('flutter', 'flutter'),
          requiredTests: const ['Linux windows_host_engine'],
          waitInterval: const Duration(seconds: 30),
          client: mockClient,
          log: logs.add,
        ).then((res) {
          completed = true;
          successResult = res;
        });

        async.elapse(const Duration(milliseconds: 10));
        expect(completed, isTrue);
        expect(successResult, isFalse);
        expect(
          logs.any(
            (l) => l.contains('Error: Non-transient 4xx error from Cocoon API'),
          ),
          isTrue,
        );
      });
    });

    test('retries on 404 - CICD not yet started', () {
      var callCount = 0;
      final mockClient = MockClient((request) async {
        callCount++;
        if (callCount == 1) {
          return _stringResponse('Not Found', 404);
        } else {
          return _stringResponse(
            _validResponseJson(
              jobs: {'Linux windows_host_engine': 'Succeeded'},
            ),
            200,
          );
        }
      });

      fakeAsync((async) {
        var completed = false;
        var successResult = false;
        final logs = <String>[];

        waitForTests(
          sha: 'd100ca3882520e04129ff2a5c09372ecec3b3860',
          slug: RepositorySlug('flutter', 'flutter'),
          requiredTests: const ['Linux windows_host_engine'],
          waitInterval: const Duration(seconds: 30),
          client: mockClient,
          log: logs.add,
        ).then((res) {
          completed = true;
          successResult = res;
        });

        // First poll: 404 logged as warning, sleep
        async.elapse(const Duration(seconds: 2));
        expect(completed, isFalse);
        expect(callCount, 1);
        expect(
          logs.any(
            (l) => l.contains('Warning: Cocoon API returned status code 404'),
          ),
          isTrue,
        );

        // Second poll: Succeeds
        async.elapse(const Duration(seconds: 29));
        expect(completed, isTrue);
        expect(successResult, isTrue);
        expect(callCount, 2);
      });
    });

    test('retries on transient 429 Too Many Requests errors', () {
      var callCount = 0;
      final mockClient = MockClient((request) async {
        callCount++;
        if (callCount == 1) {
          return _stringResponse('Too Many Requests', 429);
        } else {
          return _stringResponse(
            _validResponseJson(
              jobs: {'Linux windows_host_engine': 'Succeeded'},
            ),
            200,
          );
        }
      });

      fakeAsync((async) {
        var completed = false;
        var successResult = false;
        final logs = <String>[];

        waitForTests(
          sha: 'd100ca3882520e04129ff2a5c09372ecec3b3860',
          slug: RepositorySlug('flutter', 'flutter'),
          requiredTests: const ['Linux windows_host_engine'],
          waitInterval: const Duration(seconds: 30),
          client: mockClient,
          log: logs.add,
        ).then((res) {
          completed = true;
          successResult = res;
        });

        // First poll: 429 logged as warning, sleep
        async.elapse(const Duration(seconds: 2));
        expect(completed, isFalse);
        expect(callCount, 1);
        expect(
          logs.any(
            (l) => l.contains('Warning: Cocoon API returned status code 429'),
          ),
          isTrue,
        );

        // Second poll: Succeeds
        async.elapse(const Duration(seconds: 29));
        expect(completed, isTrue);
        expect(successResult, isTrue);
        expect(callCount, 2);
      });
    });

    test('retries when request hangs and triggers 15-second timeout', () {
      var callCount = 0;
      final mockClient = MockClient((request) async {
        callCount++;
        if (callCount == 1) {
          // Delay longer than 15 seconds to trigger timeout
          await Future<void>.delayed(const Duration(seconds: 20));
          return _stringResponse('late response', 200);
        } else {
          return _stringResponse(
            _validResponseJson(
              jobs: {'Linux windows_host_engine': 'Succeeded'},
            ),
            200,
          );
        }
      });

      fakeAsync((async) {
        var completed = false;
        var successResult = false;
        final logs = <String>[];

        waitForTests(
          sha: 'd100ca3882520e04129ff2a5c09372ecec3b3860',
          slug: RepositorySlug('flutter', 'flutter'),
          requiredTests: const ['Linux windows_host_engine'],
          waitInterval: const Duration(seconds: 30),
          client: mockClient,
          log: logs.add,
        ).then((res) {
          completed = true;
          successResult = res;
        });

        // Wait 16 seconds to elapse the 15-second timeout.
        // It triggers TimeoutException, gets caught, logged, and starts delay.
        async.elapse(const Duration(seconds: 16));
        expect(completed, isFalse);
        expect(callCount, 1);
        expect(
          logs.any(
            (l) =>
                l.contains('Warning: Error calling Cocoon API') &&
                l.contains('TimeoutException'),
          ),
          isTrue,
        );

        // Advance to trigger the second poll (30s wait interval total elapsed since start is 46s)
        async.elapse(const Duration(seconds: 30));
        expect(completed, isTrue);
        expect(successResult, isTrue);
        expect(callCount, 2);
      });
    });
  });
}

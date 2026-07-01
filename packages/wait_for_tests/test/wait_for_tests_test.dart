import 'dart:convert';
import 'package:cocoon_common/task_status.dart';
import 'package:fake_async/fake_async.dart';
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

void main() {
  group('evaluateTests', () {
    test('succeeds when all required tests succeed', () {
      final json = {
        'stages': [
          {
            'jobs': {
              'Linux windows_host_engine': 'Succeeded',
              'Mac mac_ios_engine': 'Neutral',
              'Linux linux_fuchsia': 'Skipped',
            },
          },
        ],
      };
      final requiredTests = [
        'Linux windows_host_engine',
        'Mac mac_ios_engine',
        'Linux linux_fuchsia',
      ];
      final result = evaluateTests(json: json, requiredTests: requiredTests);

      expect(result.allSucceeded, isTrue);
      expect(result.anyFailed, isFalse);
      expect(result.summaries, hasLength(3));
      expect(result.summaries[0].status, TaskStatus.succeeded);
      expect(result.summaries[1].status, TaskStatus.neutral);
      expect(result.summaries[2].status, TaskStatus.skipped);
    });

    test('fails when any required test fails', () {
      final json = {
        'stages': [
          {
            'jobs': {
              'Linux windows_host_engine': 'Succeeded',
              'Mac mac_ios_engine': 'Failed',
            },
          },
        ],
      };
      final requiredTests = ['Linux windows_host_engine', 'Mac mac_ios_engine'];
      final result = evaluateTests(json: json, requiredTests: requiredTests);

      expect(result.allSucceeded, isFalse);
      expect(result.anyFailed, isTrue);
      expect(result.summaries[1].status, TaskStatus.failed);
    });

    test('is pending when some tests are in progress or waiting', () {
      final json = {
        'stages': [
          {
            'jobs': {
              'Linux windows_host_engine': 'Succeeded',
              'Mac mac_ios_engine': 'In Progress',
            },
          },
        ],
      };
      final requiredTests = ['Linux windows_host_engine', 'Mac mac_ios_engine'];
      final result = evaluateTests(json: json, requiredTests: requiredTests);

      expect(result.allSucceeded, isFalse);
      expect(result.anyFailed, isFalse);
      expect(result.summaries[1].status, TaskStatus.inProgress);
    });

    test('treats missing required tests as waiting', () {
      final json = {
        'stages': [
          {
            'jobs': {'Linux windows_host_engine': 'Succeeded'},
          },
        ],
      };
      final requiredTests = ['Linux windows_host_engine', 'Mac mac_ios_engine'];
      final result = evaluateTests(json: json, requiredTests: requiredTests);

      expect(result.allSucceeded, isFalse);
      expect(result.anyFailed, isFalse);
      expect(result.summaries[1].status, TaskStatus.waitingForBackfill);
      expect(result.summaries[1].originalStatusString, 'Not yet scheduled');
    });

    test('is case-insensitive and trims whitespace on job name matching', () {
      final json = {
        'stages': [
          {
            'jobs': {'  Linux windows_host_engine  ': 'Succeeded'},
          },
        ],
      };
      final requiredTests = ['linux windows_host_engine'];
      final result = evaluateTests(json: json, requiredTests: requiredTests);

      expect(result.allSucceeded, isTrue);
      expect(result.anyFailed, isFalse);
    });

    test('correctly parses various status string variations', () {
      final statusMap = {
        'success': TaskStatus.succeeded,
        'succeeded': TaskStatus.succeeded,
        'neutral': TaskStatus.neutral,
        'skipped': TaskStatus.skipped,
        'failed': TaskStatus.failed,
        'infra_failure': TaskStatus.infraFailure,
        'infrafailure': TaskStatus.infraFailure,
        'cancelled': TaskStatus.cancelled,
        'canceled': TaskStatus.cancelled,
        'inprogress': TaskStatus.inProgress,
        'in_progress': TaskStatus.inProgress,
        'running': TaskStatus.inProgress,
        'new': TaskStatus.waitingForBackfill,
        'pending': TaskStatus.waitingForBackfill,
        'waiting': TaskStatus.waitingForBackfill,
        'queued': TaskStatus.waitingForBackfill,
        'scheduled': TaskStatus.waitingForBackfill,
        'some_weird_unsupported_status': TaskStatus.waitingForBackfill,
      };

      for (final MapEntry(key: inputStatus, value: expectedStatus)
          in statusMap.entries) {
        final json = {
          'stages': [
            {
              'jobs': {'test_job': inputStatus},
            },
          ],
        };
        final result = evaluateTests(json: json, requiredTests: ['test_job']);
        expect(
          result.summaries[0].status,
          expectedStatus,
          reason: 'Failed to parse "$inputStatus" to $expectedStatus',
        );
      }
    });

    test(
      'isGuardFailed causes anyFailed to be true even when requiredTests is provided and has no failed tests',
      () {
        final json = {
          'guard_status': 'infra_failure',
          'stages': [
            {
              'jobs': {'Linux windows_host_engine': 'Succeeded'},
            },
          ],
        };
        final requiredTests = ['Linux windows_host_engine'];
        final result = evaluateTests(json: json, requiredTests: requiredTests);

        expect(result.allSucceeded, isTrue);
        expect(result.anyFailed, isTrue);
      },
    );
  });

  group('waitForTests with fake_async', () {
    test('returns immediately on success on first check', () {
      final mockClient = MockClient((request) async {
        return _stringResponse('''
        {
          "stages": [
            {
              "jobs": {
                "Linux windows_host_engine": "Succeeded"
              }
            }
          ]
        }
        ''', 200);
      });

      fakeAsync((async) {
        var completed = false;
        var successResult = false;

        waitForTests(
          sha: 'd100ca3882520e04129ff2a5c09372ecec3b3860',
          repo: 'flutter',
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
        return _stringResponse('''
        {
          "stages": [
            {
              "jobs": {
                "Linux windows_host_engine": "Failed"
              }
            }
          ]
        }
        ''', 200);
      });

      fakeAsync((async) {
        var completed = false;
        var successResult = true;

        waitForTests(
          sha: 'd100ca3882520e04129ff2a5c09372ecec3b3860',
          repo: 'flutter',
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
          return _stringResponse('''
          {
            "stages": [
              {
                "jobs": {
                  "Linux windows_host_engine": "In progress"
                }
              }
            ]
          }
          ''', 200);
        } else {
          return _stringResponse('''
          {
            "stages": [
              {
                "jobs": {
                  "Linux windows_host_engine": "Succeeded"
                }
              }
            ]
          }
          ''', 200);
        }
      });

      fakeAsync((async) {
        var completed = false;
        var successResult = false;

        waitForTests(
          sha: 'd100ca3882520e04129ff2a5c09372ecec3b3860',
          repo: 'flutter',
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
          return _stringResponse('''
          {
            "stages": [
              {
                "jobs": {
                  "Linux windows_host_engine": "In progress"
                }
              }
            ]
          }
          ''', 200);
        } else {
          return _stringResponse('''
          {
            "stages": [
              {
                "jobs": {
                  "Linux windows_host_engine": "Failed"
                }
              }
            ]
          }
          ''', 200);
        }
      });

      fakeAsync((async) {
        var completed = false;
        var successResult = true;

        waitForTests(
          sha: 'd100ca3882520e04129ff2a5c09372ecec3b3860',
          repo: 'flutter',
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
        return _stringResponse('''
        {
          "stages": [
            {
              "jobs": {
                "Linux windows_host_engine": "In progress"
              }
            }
          ]
        }
        ''', 200);
      });

      fakeAsync((async) {
        var completed = false;
        var successResult = true;

        waitForTests(
          sha: 'd100ca3882520e04129ff2a5c09372ecec3b3860',
          repo: 'flutter',
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
          return _stringResponse('''
          {
            "guard_status": "In progress",
            "stages": [
              {
                "jobs": {
                  "Linux windows_host_engine": "Succeeded",
                  "Mac mac_ios_engine": "In progress"
                }
              }
            ]
          }
          ''', 200);
        } else {
          return _stringResponse('''
          {
            "guard_status": "Succeeded",
            "stages": [
              {
                "jobs": {
                  "Linux windows_host_engine": "Succeeded",
                  "Mac mac_ios_engine": "Succeeded"
                }
              }
            ]
          }
          ''', 200);
        }
      });

      fakeAsync((async) {
        var completed = false;
        var successResult = false;

        waitForTests(
          sha: 'd100ca3882520e04129ff2a5c09372ecec3b3860',
          repo: 'flutter',
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
        return _stringResponse('''
        {
          "guard_status": "Failed",
          "stages": [
            {
              "jobs": {
                "Linux windows_host_engine": "Failed",
                "Mac mac_ios_engine": "Succeeded"
              }
            }
          ]
        }
        ''', 200);
      });

      fakeAsync((async) {
        var completed = false;
        var successResult = true;

        waitForTests(
          sha: 'd100ca3882520e04129ff2a5c09372ecec3b3860',
          repo: 'flutter',
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
          return _stringResponse('''
          {
            "stages": [
              {
                "jobs": {
                  "Linux windows_host_engine": "Succeeded"
                }
              }
            ]
          }
          ''', 200);
        }
      });

      fakeAsync((async) {
        var completed = false;
        var successResult = false;
        final logs = <String>[];

        waitForTests(
          sha: 'd100ca3882520e04129ff2a5c09372ecec3b3860',
          repo: 'flutter',
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
          return _stringResponse('''
          {
            "stages": [
              {
                "jobs": {
                  "Linux windows_host_engine": "Succeeded"
                }
              }
            ]
          }
          ''', 200);
        }
      });

      fakeAsync((async) {
        var completed = false;
        var successResult = false;
        final logs = <String>[];

        waitForTests(
          sha: 'd100ca3882520e04129ff2a5c09372ecec3b3860',
          repo: 'flutter',
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
          return _stringResponse('''
          {
            "stages": [
              {
                "jobs": {
                  "Linux windows_host_engine": "Succeeded"
                }
              }
            ]
          }
          ''', 200);
        }
      });

      fakeAsync((async) {
        var completed = false;
        var successResult = false;
        final logs = <String>[];

        waitForTests(
          sha: 'd100ca3882520e04129ff2a5c09372ecec3b3860',
          repo: 'flutter',
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

    test('clamps waitInterval to at least 30 seconds and logs warning', () {
      final mockClient = MockClient((request) async {
        return _stringResponse('''
        {
          "stages": [
            {
              "jobs": {
                "Linux windows_host_engine": "Succeeded"
              }
            }
          ]
        }
        ''', 200);
      });

      fakeAsync((async) {
        var completed = false;
        var successResult = false;
        final logs = <String>[];

        waitForTests(
          sha: 'd100ca3882520e04129ff2a5c09372ecec3b3860',
          repo: 'flutter',
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
        return _stringResponse('''
        {
          "stages": [
            {
              "jobs": {
                "Linux windows_host_engine": "Succeeded"
              }
            }
          ]
        }
        ''', 200);
      });

      fakeAsync((async) {
        var completed = false;
        var successResult = false;
        final logs = <String>[];

        waitForTests(
          sha: 'd100ca3882520e04129ff2a5c09372ecec3b3860',
          repo: 'flutter',
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
  });
}

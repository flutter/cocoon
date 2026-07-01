// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'package:clock/clock.dart';
import 'package:cocoon_common/task_status.dart';
import 'package:http/http.dart' as http;

/// A structured summary for a specific required test.
class TestStatusSummary {
  final String name;
  final TaskStatus status;
  final String originalStatusString;

  const TestStatusSummary({
    required this.name,
    required this.status,
    required this.originalStatusString,
  });
}

/// The aggregated result of a polling check.
class PollResult {
  final bool allSucceeded;
  final bool anyFailed;
  final List<TestStatusSummary> summaries;
  final String guardStatus;
  final int remainingCount;

  const PollResult({
    required this.allSucceeded,
    required this.anyFailed,
    required this.summaries,
    required this.guardStatus,
    required this.remainingCount,
  });
}

/// Evaluates the status of the required tests based on the Cocoon API response.
PollResult evaluateTests({
  required Map<String, dynamic> json,
  required List<String> requiredTests,
}) {
  final allJobs = <String, String>{};
  if (json case {'stages': final List<dynamic> stages}) {
    for (final stage in stages) {
      if (stage case {'jobs': final Map<dynamic, dynamic> jobs}) {
        for (final MapEntry(key: String key, value: String value)
            in jobs.entries) {
          allJobs[key] = value;
        }
      }
    }
  }

  // Pre-build a normalized lookup map to avoid O(M * N) iteration
  final normalizedJobs = {
    for (final MapEntry(key: name, value: status) in allJobs.entries)
      name.trim().toLowerCase(): (name, status),
  };

  // If requiredTests is empty, evaluate all available jobs
  final targetTests = requiredTests.isNotEmpty
      ? requiredTests
      : allJobs.keys.toList();

  final summaries = <TestStatusSummary>[];
  final guardStatusStr = json['guard_status'] as String? ?? '';
  final isGuardFailed = switch (guardStatusStr.toLowerCase().replaceAll(
    ' ',
    '',
  )) {
    'failed' ||
    'infra_failure' ||
    'infrafailure' ||
    'cancelled' ||
    'canceled' => true,
    _ => false,
  };

  var allSucceeded = true;
  var anyFailed = isGuardFailed;

  for (final targetTest in targetTests) {
    final trimmedName = targetTest.trim();
    if (trimmedName.isEmpty) continue;

    final lookup = normalizedJobs[trimmedName.toLowerCase()];
    final (matchedJobName, originalStatus) = lookup ?? (null, null);

    final TaskStatus status;
    final String statusStr;

    if (originalStatus != null) {
      status = _parseStatus(originalStatus);
      statusStr = originalStatus;
    } else {
      status = TaskStatus.waitingForBackfill;
      statusStr = 'Not yet scheduled';
    }

    if (!status.isSuccess) {
      allSucceeded = false;
    }
    if (status.isFailure) {
      anyFailed = true;
    }

    summaries.add(
      TestStatusSummary(
        name: matchedJobName ?? trimmedName,
        status: status,
        originalStatusString: statusStr,
      ),
    );
  }

  final remainingCount = summaries
      .where((s) => s.status.isBuildInProgress)
      .length;

  return PollResult(
    allSucceeded: allSucceeded,
    anyFailed: anyFailed,
    summaries: summaries,
    guardStatus: guardStatusStr,
    remainingCount: remainingCount,
  );
}

TaskStatus _parseStatus(String statusStr) {
  return switch (statusStr.toLowerCase().replaceAll(' ', '')) {
    'succeeded' || 'success' => TaskStatus.succeeded,
    'neutral' => TaskStatus.neutral,
    'skipped' => TaskStatus.skipped,
    'failed' => TaskStatus.failed,
    'infra_failure' || 'infrafailure' => TaskStatus.infraFailure,
    'cancelled' || 'canceled' => TaskStatus.cancelled,
    'inprogress' || 'in_progress' || 'running' => TaskStatus.inProgress,
    'new' ||
    'pending' ||
    'waiting' ||
    'queued' ||
    'scheduled' => TaskStatus.waitingForBackfill,
    _ => TaskStatus.waitingForBackfill,
  };
}

/// Polls the Cocoon API until all required tests complete or any fails.
/// Returns true if all tests succeeded, false if any failed or loop timed out.
Future<bool> waitForTests({
  required String sha,
  required String repo,
  required List<String> requiredTests,
  required Duration waitInterval,
  required http.Client client,
  required void Function(String) log,
  Duration? timeout,
  String owner = 'flutter',
}) async {
  final clampedSeconds = waitInterval.inSeconds.clamp(30, 600);
  final clampedWaitInterval = clampedSeconds != waitInterval.inSeconds
      ? Duration(seconds: clampedSeconds)
      : waitInterval;

  final startTime = clock.now();
  final url = Uri.https(
    'flutter-dashboard.appspot.com',
    '/api/public/get-presubmit-guard',
    {'sha': sha, 'repo': repo, 'owner': owner},
  );

  log('Starting wait-for-tests polling loop.');
  log('Repository: $owner/$repo, Commit SHA: $sha');
  if (clampedSeconds != waitInterval.inSeconds) {
    log(
      'Warning: wait-interval must be between 30 and 600 seconds. Clamping from ${waitInterval.inSeconds}s to ${clampedSeconds}s.',
    );
  }

  if (requiredTests.isEmpty) {
    log('Required tests to wait for: [All scheduled tests]');
  } else {
    log('Required tests to wait for: ${requiredTests.join(", ")}');
  }
  log('Wait interval: ${clampedWaitInterval.inSeconds} seconds');

  while (true) {
    if (timeout != null && clock.now().difference(startTime) > timeout) {
      log('Error: Polling timed out after ${timeout.inMinutes} minutes.');
      return false;
    }

    try {
      final response = await client.get(url);
      if (response.statusCode != 200) {
        log(
          'Warning: Cocoon API returned status code ${response.statusCode}. Body: ${response.body}',
        );
      } else {
        Map<String, dynamic> json;
        try {
          json = jsonDecode(response.body) as Map<String, dynamic>;
        } catch (e) {
          log('Warning: Failed to parse Cocoon API response as JSON: $e');
          json = <String, dynamic>{};
        }

        if (json.isNotEmpty) {
          final result = evaluateTests(
            json: json,
            requiredTests: requiredTests,
          );

          log('\n--- Current Test Status Summary ---');
          for (final summary in result.summaries) {
            log(
              '- ${summary.name}: ${summary.status.value} (${summary.originalStatusString})',
            );
          }
          if (requiredTests.isEmpty) {
            log('Remaining tests: ${result.remainingCount}');
            log('Overall Guard Status: ${result.guardStatus}');
          }
          log('-----------------------------------\n');

          final bool isSuccess;
          if (requiredTests.isEmpty) {
            isSuccess =
                result.allSucceeded &&
                result.guardStatus.toLowerCase() == 'succeeded';
          } else {
            isSuccess = result.allSucceeded;
          }

          if (isSuccess) {
            if (requiredTests.isEmpty) {
              log(
                'Success: Overall guard status succeeded and all tests completed successfully!',
              );
            } else {
              log('Success: All required tests have completed successfully!');
            }
            return true;
          }

          if (result.anyFailed) {
            log(
              'Error: One or more tests have failed, or the overall guard status is failed.',
            );
            return false;
          }
        }
      }
    } catch (e) {
      log('Warning: Error calling Cocoon API: $e');
    }

    log('Sleeping for ${clampedWaitInterval.inSeconds} seconds...');
    await Future<void>.delayed(clampedWaitInterval);
  }
}

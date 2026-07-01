// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'package:clock/clock.dart';
import 'package:cocoon_common/guard_status.dart';
import 'package:cocoon_common/rpc_model.dart';
import 'package:cocoon_common/task_status.dart';
import 'package:github/github.dart';
import 'package:http/http.dart' as http;

/// A structured summary for a specific required test.
class TestStatusSummary {
  final String name;
  final TaskStatus status;

  const TestStatusSummary({required this.name, required this.status});
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
  required PresubmitGuardResponse response,
  required List<String> requiredTests,
}) {
  final allJobs = <String, TaskStatus>{
    for (final stage in response.stages) ...stage.jobs,
  };

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
  final isGuardFailed = response.guardStatus == GuardStatus.failed;

  var allSucceeded = true;
  var anyFailed = isGuardFailed;

  for (final targetTest in targetTests) {
    final trimmedName = targetTest.trim();
    if (trimmedName.isEmpty) continue;

    final lookup = normalizedJobs[trimmedName.toLowerCase()];
    final (matchedJobName, originalStatus) = lookup ?? (null, null);

    final TaskStatus status;

    if (originalStatus != null) {
      status = originalStatus;
    } else {
      status = TaskStatus.waitingForBackfill;
    }

    if (!status.isSuccess) {
      allSucceeded = false;
    }
    if (status.isFailure) {
      anyFailed = true;
    }

    summaries.add(
      TestStatusSummary(name: matchedJobName ?? trimmedName, status: status),
    );
  }

  final remainingCount = summaries
      .where((s) => s.status.isBuildInProgress)
      .length;

  return PollResult(
    allSucceeded: allSucceeded,
    anyFailed: anyFailed,
    summaries: summaries,
    guardStatus: response.guardStatus.value,
    remainingCount: remainingCount,
  );
}

/// Polls the Cocoon API until all required tests complete or any fails.
/// Returns true if all tests succeeded, false if any failed or loop timed out.
Future<bool> waitForTests({
  required String sha,
  required RepositorySlug slug,
  required List<String> requiredTests,
  required Duration waitInterval,
  required http.Client client,
  required void Function(String) log,
  Duration? timeout,
}) async {
  final clampedSeconds = waitInterval.inSeconds.clamp(30, 600);
  final clampedWaitInterval = clampedSeconds != waitInterval.inSeconds
      ? Duration(seconds: clampedSeconds)
      : waitInterval;

  final startTime = clock.now();
  final url = Uri.https(
    'flutter-dashboard.appspot.com',
    '/api/public/get-presubmit-guard',
    {'sha': sha, 'repo': slug.name, 'owner': slug.owner},
  );

  log('Starting wait-for-tests polling loop.');
  log('Repository: $slug, Commit SHA: $sha');
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

  while (timeout == null || clock.now().difference(startTime) <= timeout) {
    final http.Response response;
    try {
      response = await client.get(url).timeout(const Duration(seconds: 15));
    } on Exception catch (e) {
      log('Warning: Error calling Cocoon API: $e');
      log('Sleeping for ${clampedWaitInterval.inSeconds} seconds...');
      await Future<void>.delayed(clampedWaitInterval);
      continue;
    }

    // Handle error cases and either fail fast or sleep / retry.
    if (response.statusCode != 200) {
      final failImmediately = switch (response.statusCode) {
        // 404: we might not have created a check run yet.
        // 408: request timed out on server.
        // 429: try again
        404 || 429 || 408 => false,
        >= 400 && < 500 => true,
        _ => false,
      };

      if (failImmediately) {
        log(
          'Error: Non-transient 4xx error from Cocoon API. Status code ${response.statusCode}. Body: ${response.body}',
        );
        return false;
      }
      log(
        'Warning: Cocoon API returned status code ${response.statusCode}. Body: ${response.body}',
      );
      log('Sleeping for ${clampedWaitInterval.inSeconds} seconds...');
      await Future<void>.delayed(clampedWaitInterval);
      continue;
    }

    // Success case.
    Map<String, Object?> json;
    try {
      json = jsonDecode(response.body) as Map<String, Object?>;
    } catch (e) {
      log('Warning: Failed to parse Cocoon API response as JSON: $e');
      log('Sleeping for ${clampedWaitInterval.inSeconds} seconds...');
      await Future<void>.delayed(clampedWaitInterval);
      continue;
    }

    final PresubmitGuardResponse guardResponse;
    try {
      guardResponse = PresubmitGuardResponse.fromJson(json);
    } catch (e) {
      log('Warning: Failed to parse JSON into PresubmitGuardResponse: $e');
      log('Sleeping for ${clampedWaitInterval.inSeconds} seconds...');
      await Future<void>.delayed(clampedWaitInterval);
      continue;
    }

    final result = evaluateTests(
      response: guardResponse,
      requiredTests: requiredTests,
    );

    log('\n--- Current Test Status Summary ---');
    for (final summary in result.summaries) {
      log('- ${summary.name}: ${summary.status.value}');
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

    log('Sleeping for ${clampedWaitInterval.inSeconds} seconds...');
    await Future<void>.delayed(clampedWaitInterval);
  }

  log('Error: Polling timed out after ${timeout.inMinutes} minutes.');
  return false;
}

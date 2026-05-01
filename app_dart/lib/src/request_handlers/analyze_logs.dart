// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:cocoon_server/logging.dart' show log;
import 'package:collection/collection.dart';
import 'package:fixnum/fixnum.dart';
import 'package:github/github.dart';
import 'package:retry/retry.dart';

import '../../cocoon_service.dart';
import '../request_handling/api_request_handler.dart';
import '../request_handling/exceptions.dart';
import '../service/firestore/unified_check_run.dart';
import '../service/log_analyzer.dart';

/// Analyzes failed build logs using Genkit.
///
/// POST: /api/analyze-logs
///
/// Parameters:
///   owner: (string in body) optional. The GitHub repository owner. Defaults to 'flutter'.
///   repo: (string in body) optional. The GitHub repository name. Defaults to 'flutter'.
///   pr: (int in body) mandatory. The Pull Request number.
///   build_id: (int in body) mandatory. The LUCI build ID.
final class AnalyzeLogs extends ApiRequestHandler {
  const AnalyzeLogs({
    required super.config,
    required super.authenticationProvider,
    required LuciBuildService luciBuildService,
    required FirestoreService firestore,
    required LogAnalyzer logAnalyzer,
  }) : _luciBuildService = luciBuildService,
       _firestore = firestore,
       _logAnalyzer = logAnalyzer;

  final LuciBuildService _luciBuildService;
  final FirestoreService _firestore;
  final LogAnalyzer _logAnalyzer;

  static const String kOwnerParam = 'owner';
  static const String kRepoParam = 'repo';
  static const String kPrParam = 'pr';
  static const String kBuildIdParam = 'build_id';

  @override
  Future<Response> post(Request request) async {
    final requestData = await request.readBodyAsJson();
    checkRequiredParameters(requestData, [kPrParam, kBuildIdParam]);

    final owner = requestData[kOwnerParam] as String? ?? 'flutter';
    final repo = requestData[kRepoParam] as String? ?? 'flutter';
    final prNumber = requestData[kPrParam] as int;
    final buildId = requestData[kBuildIdParam] as int;

    final slug = RepositorySlug(owner, repo);

    // 1. Validate that job with provided build_id belongs to latest presubmit guard.
    final guard = await UnifiedCheckRun.getLatestPresubmitGuardForPrNum(
      firestoreService: _firestore,
      slug: slug,
      prNum: prNumber,
    );

    if (guard == null) {
      throw NotFoundException(
        'No PresubmitGuard found for PR $slug/#$prNumber',
      );
    }

    final jobs = await UnifiedCheckRun.queryAllPresubmitJobsForGuard(
      firestoreService: _firestore,
      checkRunId: guard.checkRunId,
    );

    final job = jobs.firstWhereOrNull((j) => j.buildId == buildId);
    if (job == null) {
      throw BadRequestException(
        'Job with build_id $buildId does not belong to the latest presubmit guard for PR $slug/#$prNumber',
      );
    }

    // 2. Call _luciBuildService.getBuildById providing buildId and BuildMask.
    final build = await _luciBuildService.getBuildById(
      Int64(buildId),
      buildMask: bbv2.BuildMask(
        fields: bbv2.FieldMask(paths: ['steps', 'tags']),
      ),
    );

    // 3. Extract logs and tags.
    final stdoutLogs = <String>[];
    for (final step in build.steps) {
      if (step.status == bbv2.Status.FAILURE ||
          step.status == bbv2.Status.INFRA_FAILURE) {
        for (final log in step.logs) {
          if (log.name == 'stdout') {
            stdoutLogs.add(log.url);
          }
        }
      }
    }
    if (stdoutLogs.isEmpty) {
      throw NotFoundException('Logs Not Found for BuildId: $buildId');
    }
    String githubUrl;
    final githubLinkTag = build.tags.firstWhereOrNull(
      (tag) => tag.key == 'github_link',
    );
    if (githubLinkTag == null) {
      log.warn('Could not find github_link tag in build $buildId');
      githubUrl = 'http://github.com/$owner/$repo/pull/$prNumber';
    } else {
      githubUrl = githubLinkTag.value;
    }

    // 4. Feed text to genkit.
    final prompt =
        '''You are a Senior Infrastructure Engineer specializing in the Flutter CI ecosystem.
I will provide you with a link to github pull request and the logs of a failed build step in a LUCI build associated with that change.

## Your task

### 1. Identify the specific test or command that failed.

### 2. Extract the error message or crash log.

### 3. Explain the most likely root cause in simple terms.

### 4. Suggest a potential fix if possible.

## Workflow

### 1. Analyze Raw Log Output

Analyze the raw log output for failure details. Do not skim the output; check the entire log. **The description of findings should include specific details for the failures (e.g., unformatted files, specific test names), not just the top-level command that failed.**

### 2. Look for Failure Patterns

#### Pattern A: Error Blocks (e.g., Linux Analyze)
Search for blocks starting with `╡ERROR #`.
Example:
```
╔═╡ERROR #1╞════════════════════════════════════════════════════════════════════
║ Command: bin/cache/dart-sdk/bin/dart --enable-asserts /b/s/w/ir/x/w/flutter/dev/bots/analyze_snippet_code.dart --verbose
║ Command exited with exit code 255 but expected zero exit code.
║ Working directory: /b/s/w/ir/x/w/flutter
╚═══════════════════════════════════════════════════════════════════════════════
```

#### Pattern B: Task Result JSON
Search for "Task result:" followed by a JSON object.
Example:
```json
Task result:
{
  "success": false,
  "reason": "Task failed: PathNotFoundException: Cannot open file..."
}
```

#### Pattern C: Failing Tests List
For general Dart tests, look for a list at the end of the log starting with "Failing tests:".
Example:
```
Failing tests:
  test/general.shard/cache_test.dart: FontSubset artifacts for all platforms on arm64 hosts
  test/general.shard/cache_test.dart: FontSubset artifacts on arm64 linux
```

#### Pattern D: Build Failures
For build failures (e.g., engine tests failing at compile time), look for the following indicators in the logs or API summaries:
- Lines starting with `FAILED:` (indicates a Ninja target failed).
- Compiler error messages (e.g., `error:`, `fatal error:`).
- Linker error messages (e.g., `undefined reference to`).
- Summary messages in the check-runs API output like `1 build failed: [<build_name>]`.

## Links

Link to GitHub Pull Request: $githubUrl
Links to Logs: ${stdoutLogs.join('\n')}
''';

    final analysis = await _logAnalyzer.analyze(prompt: prompt);

    // 5. Store response in log_analysis of a presubmit_jobs.
    const r = RetryOptions(maxAttempts: 10, maxDelay: Duration(minutes: 2));
    try {
      await r.retry(() {
        return UnifiedCheckRun.storeLogAnalysis(
          firestoreService: _firestore,
          job: job,
          analysis: analysis,
        );
      });
    } on Exception catch (e, s) {
      log.warn('Failed to store log analysis', e, s);
      rethrow;
    }

    return Response.emptyOk;
  }
}

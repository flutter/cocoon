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
    String? githubUrl;
    for (final tag in build.tags) {
      if (tag.key == 'github_link') {
        githubUrl = tag.value;
      }
    }

    // 4. Feed text to genkit.
    final prompt =
        '''
You are a Senior Infrastructure Engineer specializing in the Flutter CI ecosystem.

I will provide you with github pull request and the logs of a failed build step in a LUCI build associated with that change.

Your task is:

1. Identify the specific test or command that failed.

2. Extract the error message or crash log.

3. Explain the most likely root cause in simple terms.

4. Suggest a potential fix if possible.

${githubUrl != null && githubUrl.isNotEmpty ? 'Link to GitHub Pull Request: $githubUrl' : ''}

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

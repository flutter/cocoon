// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cocoon_server/logging.dart';
import 'package:github/github.dart';
import 'package:googleapis/bigquery/v2.dart';
import 'package:retry/retry.dart';
import 'package:yaml/yaml.dart';

import '../../cocoon_service.dart';
import '../../protos.dart' as pb;
import '../foundation/typedefs.dart';
import '../model/ci_yaml/ci_yaml.dart';
import '../model/ci_yaml/target.dart';
import '../request_handlers/flaky_handler_utils.dart';
import '../request_handling/exceptions.dart';
import '../service/get_files_changed.dart';

const String kCiYamlPath = '.ci.yaml';
const String kCiYamlFusionEnginePath = 'engine/src/flutter/$kCiYamlPath';
const String kTestOwnerPath = 'TESTOWNERS';

/// Attempts to parse the github merge queue branch into its constituent parts to be returned as a record.
({bool parsed, String branch, int pullRequestNumber})
tryParseGitHubMergeQueueBranch(String branch) {
  final match = _githubMqBranch.firstMatch(branch);
  if (match == null) {
    return notGitHubMergeQueueBranch;
  }

  return (
    parsed: true,
    branch: match.group(1)!,
    pullRequestNumber: int.parse(match.group(2)!),
  );
}

const notGitHubMergeQueueBranch = (
  parsed: false,
  branch: '',
  pullRequestNumber: -1,
);

final _githubMqBranch = RegExp(
  r'^gh-readonly-queue\/([^/]+)\/pr-(\d+)-([a-fA-F0-9]+)$',
);

const _githubTimeout = Duration(seconds: 5);
const _githubRetryOptions = RetryOptions(
  maxAttempts: 3,
  delayFactor: Duration(seconds: 3),
);

/// Get content of [filePath] from GitHub CDN.
Future<String> githubFileContent(
  RepositorySlug slug,
  String filePath, {
  required HttpClientProvider httpClientProvider,
  String ref = 'master',
  Duration timeout = _githubTimeout,
  RetryOptions retryOptions = _githubRetryOptions,
}) async {
  final githubUrl = Uri.https(
    'raw.githubusercontent.com',
    '${slug.fullName}/$ref/$filePath',
  );
  // git-on-borg has a different path for shas and refs to github
  final gobRef = (ref.length < 40) ? 'refs/heads/$ref' : ref;
  final gobUrl = Uri.https(
    'flutter.googlesource.com',
    'mirrors/${slug.name}/+/$gobRef/$filePath',
    <String, String>{'format': 'text'},
  );
  late final String content;
  try {
    await retryOptions.retry(
      () async =>
          content = await getUrl(
            githubUrl,
            httpClientProvider,
            timeout: timeout,
          ),
      retryIf: (Exception e) => e is HttpException || e is NotFoundException,
    );
  } on Exception catch (e) {
    // A logical error (i.e. something like an ArgumentError) should not be
    // used as a retry signal. For example, 'TestFailure' (package:test) is an
    // exception but is not recoverable.
    if (e is! HttpException && e is! NotFoundException) {
      rethrow;
    }
    log.warn('Failed to fetch $githubUrl, falling back to $gobUrl', e);
    await retryOptions.retry(() async {
      content = String.fromCharCodes(
        base64Decode(
          await getUrl(gobUrl, httpClientProvider, timeout: timeout),
        ),
      );
    }, retryIf: (e) => e is HttpException);
  }
  return content;
}

/// Return [String] of response from [url] if status is [HttpStatus.ok].
///
/// If [url] returns [HttpStatus.notFound] throw [NotFoundException].
/// Otherwise, throws [HttpException].
FutureOr<String> getUrl(
  Uri url,
  HttpClientProvider httpClientProvider, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  log.info('Making HTTP GET request for $url');
  final client = httpClientProvider();
  try {
    final response = await client.get(url).timeout(timeout);

    if (response.statusCode == HttpStatus.ok) {
      return response.body;
    } else if (response.statusCode == HttpStatus.notFound) {
      throw NotFoundException('HTTP ${response.statusCode}: $url');
    } else {
      log.warn('HTTP ${response.statusCode}: $url');
      throw HttpException('HTTP ${response.statusCode}: $url');
    }
  } finally {
    client.close();
  }
}

/// Returns a LUCI [builder] list that covers changed [files].
///
/// [builders]: enabled luci builders.
/// [files]: changed files in corresponding PRs.
///
/// [builder] format with run_if:
/// {
///   "name":"yyy",
///   "repo":"flutter",
///   "taskName":"zzz",
///   "enabled":true,
///   "run_if":["a/b/", "c/d_e/**", "f", "g*h/"]
/// }
/// [builder] format with run_if_not:
/// {
///   "name":"yyy",
///   "repo":"flutter",
///   "taskName":"zzz",
///   "enabled":true,
///   "run_if_not":["a/b/", "c/d_e/**", "f", "g*h/"]
/// }
/// Note: if both [run_if] and [run_if_not] are provided and not empty only
/// [run_if] is evaluated.
///
/// [file] is based on repo root: `a/b/c.dart`.
Future<List<Target>> getTargetsToRun(
  Iterable<Target> targets,
  FilesChanged filesChanged,
) async {
  log.info('Getting targets to run from diff.');

  // If we were not able to determine what files were changed run all targets.
  switch (filesChanged) {
    case InconclusiveFilesChanged(:final pullRequestNumber, :final reason):
      log.info('Running all targets on PR#$pullRequestNumber: $reason');
      return [...targets];
    case SuccessfulFilesChanged(:final pullRequestNumber, :final filesChanged):
      final targetsToRun = <Target>[];
      for (final target in targets) {
        final globs = target.runIf;
        // Handle case where [Target] initializes empty runif
        if (globs.isEmpty) {
          targetsToRun.add(target);
        } else {
          for (final glob in globs) {
            // If a file is found within a pre-set dir, the builder needs to run. No need to check further.
            final regExp = _convertGlobToRegExp(glob);
            if (glob.isEmpty || filesChanged.any(regExp.hasMatch)) {
              targetsToRun.add(target);
              break;
            }
          }
        }
      }

      log.info(
        'Running a subset of targets on PR#$pullRequestNumber: ${targetsToRun.map((t) => t.name).join(', ')}',
      );

      return targetsToRun;
  }
}

/// Expands globs string to a regex for evaluation.
RegExp _convertGlobToRegExp(String glob) {
  glob = glob.replaceAll('**', '[A-Za-z0-9_/.]+');
  glob = glob.replaceAll('*', '[A-Za-z0-9_.]+');
  return RegExp('^$glob\$');
}

Future<void> insertBigQuery(
  String tableName,
  Map<String, dynamic> data,
  TabledataResource tabledataResourceApi,
) async {
  // Define const variables for [BigQuery] operations.
  const projectId = 'flutter-dashboard';
  const dataset = 'cocoon';
  final table = tableName;
  final requestRows = <Map<String, Object>>[];

  requestRows.add(<String, Object>{'json': data});

  // Obtain [rows] to be inserted to [BigQuery].
  final request = TableDataInsertAllRequest.fromJson(<String, dynamic>{
    'rows': requestRows,
  });

  try {
    await tabledataResourceApi.insertAll(request, projectId, dataset, table);
  } on ApiRequestError catch (e) {
    log.warn('Failed to add to BigQuery', e);
  }
}

/// Validate test ownership defined in [testOwnersContent] for tests configured in `ciYamlContent`.
List<String> validateOwnership(
  String ciYamlContent,
  String testOwnersContent, {
  bool unfilteredTargets = false,
}) {
  final noOwnerBuilders = <String>[];
  final ciYaml = loadYaml(ciYamlContent) as YamlMap?;
  final unCheckedSchedulerConfig =
      pb.SchedulerConfig()..mergeFromProto3Json(ciYaml);

  final ciYamlFromProto = CiYamlSet(
    slug: Config.flutterSlug,
    branch: Config.defaultBranch(Config.flutterSlug),
    yamls: {CiType.any: unCheckedSchedulerConfig},
  );

  final schedulerConfig = ciYamlFromProto.configFor(CiType.any);

  for (var target in schedulerConfig.targets) {
    final builder = target.name;
    final builderType = getTypeForBuilder(
      builder,
      ciYamlFromProto,
      unfilteredTargets: unfilteredTargets,
    );

    final owner =
        getTestOwnership(target, builderType, testOwnersContent).owner;
    print('$builder: $owner');
    if (owner == null) {
      noOwnerBuilders.add(builder);
    }
  }
  return noOwnerBuilders;
}

/// Utility to class to wrap related objects in.
class Tuple<S, T, U> {
  const Tuple(this.first, this.second, this.third);

  final S first;
  final T second;
  final U third;
}

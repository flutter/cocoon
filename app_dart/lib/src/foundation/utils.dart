// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cocoon_service/cocoon_service.dart';
import 'package:github/github.dart';
import 'package:googleapis/bigquery/v2.dart';
import 'package:http/http.dart' as http;
import 'package:retry/retry.dart';
import 'package:yaml/yaml.dart';

import '../../protos.dart' as pb;
import '../foundation/typedefs.dart';
import '../model/ci_yaml/ci_yaml.dart';
import '../model/ci_yaml/target.dart';
import '../request_handlers/flaky_handler_utils.dart';
import '../request_handling/exceptions.dart';
import '../service/logging.dart';

const String kCiYamlPath = '.ci.yaml';
const String kTestOwnerPath = 'TESTOWNERS';

/// Signature for a function that calculates the backoff duration to wait in
/// between requests when GitHub responds with an error.
///
/// The [attempt] argument is zero-based, so if the first attempt to request
/// from GitHub fails, and we're backing off before making the second attempt,
/// the [attempt] argument will be zero.
typedef GitHubBackoffCalculator = Duration Function(int attempt);

/// Default backoff calculator.
Duration twoSecondLinearBackoff(int attempt) {
  return const Duration(seconds: 2) * (attempt + 1);
}

/// Get content of [filePath] from GitHub CDN.
Future<String> githubFileContent(
  RepositorySlug slug,
  String filePath, {
  required HttpClientProvider httpClientProvider,
  String ref = 'master',
  Duration timeout = const Duration(seconds: 5),
  RetryOptions retryOptions = const RetryOptions(
    maxAttempts: 3,
    delayFactor: Duration(seconds: 3),
  ),
}) async {
  final Uri githubUrl = Uri.https('raw.githubusercontent.com', '${slug.fullName}/$ref/$filePath');
  // git-on-borg has a different path for shas and refs to github
  final String gobRef = (ref.length < 40) ? 'refs/heads/$ref' : ref;
  final Uri gobUrl = Uri.https(
    'flutter.googlesource.com',
    'mirrors/${slug.name}/+/$gobRef/$filePath',
    <String, String>{
      'format': 'text',
    },
  );
  late String content;
  try {
    await retryOptions.retry(
      () async => content = await getUrl(githubUrl, httpClientProvider, timeout: timeout),
      retryIf: (Exception e) => e is HttpException || e is NotFoundException,
    );
  } catch (e) {
    await retryOptions.retry(
      () async =>
          content = String.fromCharCodes(base64Decode(await getUrl(gobUrl, httpClientProvider, timeout: timeout))),
      retryIf: (Exception e) => e is HttpException,
    );
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
  final http.Client client = httpClientProvider();
  try {
    final http.Response response = await client.get(url).timeout(timeout);

    if (response.statusCode == HttpStatus.ok) {
      return response.body;
    } else if (response.statusCode == HttpStatus.notFound) {
      throw NotFoundException('HTTP ${response.statusCode}: $url');
    } else {
      log.warning('HTTP ${response.statusCode}: $url');
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
/// [builder] is with format:
/// {
///   "name":"yyy",
///   "repo":"flutter",
///   "taskName":"zzz",
///   "enabled":true,
///   "run_if":["a/b/", "c/d_e/**", "f", "g*h/"]
/// }
///
/// [file] is based on repo root: `a/b/c.dart`.
Future<List<Target>> getTargetsToRun(Iterable<Target> targets, List<String?> files) async {
  log.info('Getting targets to run from diff.');
  final List<Target> targetsToRun = <Target>[];
  for (Target target in targets) {
    final List<String> globs = target.value.runIf;
    // Handle case where [Target] initializes empty runif
    if (globs.isEmpty) {
      targetsToRun.add(target);
    }

    for (String glob in globs) {
      glob = glob.replaceAll('**', '[A-Za-z0-9_/.]+');
      glob = glob.replaceAll('*', '[A-Za-z0-9_.]+');
      // If a file is found within a pre-set dir, the builder needs to run. No need to check further.
      final RegExp regExp = RegExp('^$glob\$');
      if (glob.isEmpty || files.any((String? file) => regExp.hasMatch(file!))) {
        targetsToRun.add(target);
        break;
      }
    }
  }

  log.info('Collected the following targets to run:');
  for (var target in targetsToRun) {
    log.info(target.value.name);
  }

  return targetsToRun;
}

Future<void> insertBigquery(String tableName, Map<String, dynamic> data, TabledataResource tabledataResourceApi) async {
  // Define const variables for [BigQuery] operations.
  const String projectId = 'flutter-dashboard';
  const String dataset = 'cocoon';
  final String table = tableName;
  final List<Map<String, Object>> requestRows = <Map<String, Object>>[];

  requestRows.add(<String, Object>{
    'json': data,
  });

  // Obtain [rows] to be inserted to [BigQuery].
  final TableDataInsertAllRequest request = TableDataInsertAllRequest.fromJson(<String, dynamic>{'rows': requestRows});

  try {
    await tabledataResourceApi.insertAll(request, projectId, dataset, table);
  } on ApiRequestError catch (error) {
    log.warning('Failed to add to BigQuery: $error');
  }
}

/// Validate test ownership defined in [testOwnersContent] for tests configured in `ciYamlContent`.
List<String> validateOwnership(String ciYamlContent, String testOwnersContent, {bool unfilteredTargets = false}) {
  final List<String> noOwnerBuilders = <String>[];
  final YamlMap? ciYaml = loadYaml(ciYamlContent) as YamlMap?;
  final pb.SchedulerConfig unCheckedSchedulerConfig = pb.SchedulerConfig()..mergeFromProto3Json(ciYaml);

  final CiYaml ciYamlFromProto = CiYaml(
    slug: Config.flutterSlug,
    branch: Config.defaultBranch(Config.flutterSlug),
    config: unCheckedSchedulerConfig,
  );

  final pb.SchedulerConfig schedulerConfig = ciYamlFromProto.config;

  // TODO this is where to enforce task name for devicelab.
  for (pb.Target target in schedulerConfig.targets) {
    String builder = target.name;
    final BuilderType builderType = getTypeForBuilder(
      builder,
      ciYamlFromProto,
      unfilteredTargets: unfilteredTargets,
    );

    if (builderType == BuilderType.devicelab) {
      builder = target.properties['task_name']!;
    }

    final String? owner = getTestOwnership(
      target,
      builderType,
      testOwnersContent,
    ).owner;
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

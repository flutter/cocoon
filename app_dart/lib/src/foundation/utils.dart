// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

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
import '../service/luci.dart';

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

/// Gets supported branch list of `flutter/flutter` via GitHub http request.
Future<Uint8List> getBranches(
  HttpClientProvider httpClientProvider, {
  RetryOptions retryOptions = const RetryOptions(maxAttempts: 3),
}) async {
  String content;
  try {
    content = await githubFileContent(
      RepositorySlug('flutter', 'cocoon'),
      'app_dart/dev/branches.txt',
      httpClientProvider: httpClientProvider,
      retryOptions: retryOptions,
    );
  } on HttpException {
    log.warning('githubFileContent failed to get branches');
    content = 'master';
  }

  final List<String> branches = content.split('\n').map((String branch) => branch.trim()).toList();
  branches.removeWhere((String branch) => branch.isEmpty);
  return Uint8List.fromList(branches.join(',').codeUnits);
}

Future<RepositorySlug?> repoNameForBuilder(List<LuciBuilder> builders, String builderName) async {
  final LuciBuilder builderConfig = builders.firstWhere(
    (LuciBuilder builder) => builder.name == builderName,
    orElse: () => const LuciBuilder(repo: '', name: '', flaky: false),
  );
  final String repoName = builderConfig.repo!;
  // If there is no builder config for the builderName then we
  // return null. This is to allow the code calling this method
  // to skip changes that depend on builder configurations.
  if (repoName.isEmpty) {
    return null;
  }
  return RepositorySlug('flutter', repoName);
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
  final List<Target> targetsToRun = <Target>[];
  for (Target target in targets) {
    final List<String> globs = target.value.runIf;
    // Handle case where [Target] initializes empty runif
    if (globs.isEmpty) {
      targetsToRun.add(target);
    }
    for (String glob in globs) {
      glob = glob.replaceAll('**', '[a-zA-Z_/]?');
      glob = glob.replaceAll('*', '[a-zA-Z_/]*');
      // If a file is found within a pre-set dir, the builder needs to run. No need to check further.
      final RegExp regExp = RegExp('^$glob');
      if (glob.isEmpty || files.any((String? file) => regExp.hasMatch(file!))) {
        targetsToRun.add(target);
        break;
      }
    }
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
List<String> validateOwnership(String ciYamlContent, String testOwnersContent) {
  final List<String> noOwnerBuilders = <String>[];
  final YamlMap? ciYaml = loadYaml(ciYamlContent) as YamlMap?;
  final pb.SchedulerConfig unCheckedSchedulerConfig = pb.SchedulerConfig()..mergeFromProto3Json(ciYaml);
  final pb.SchedulerConfig schedulerConfig = CiYaml(
    slug: Config.flutterSlug,
    branch: Config.defaultBranch(Config.flutterSlug),
    config: unCheckedSchedulerConfig,
  ).config;
  for (pb.Target target in schedulerConfig.targets) {
    final String builder = target.name;
    final String? owner = getTestOwnership(builder, getTypeForBuilder(builder, ciYaml!), testOwnersContent).owner;
    print('$builder: $owner');
    if (owner == null) {
      noOwnerBuilders.add(builder);
    }
  }
  return noOwnerBuilders;
}

/// Utility to class to wrap related objects in.
class Pair<S, T> {
  const Pair(this.first, this.second);

  final S first;
  final T second;
}

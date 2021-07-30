// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:appengine/appengine.dart';
import 'package:github/github.dart';
import 'package:googleapis/bigquery/v2.dart';
import 'package:meta/meta.dart';
import 'package:retry/retry.dart';
import 'package:yaml/yaml.dart';

import '../../protos.dart';
import '../foundation/typedefs.dart';
import '../request_handlers/flaky_handler_utils.dart';
import '../request_handling/exceptions.dart';
import '../service/luci.dart';
import '../service/scheduler/graph.dart';

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
  String filePath, {
  @required HttpClientProvider httpClientProvider,
  Logging log,
  Duration timeout = const Duration(seconds: 5),
  RetryOptions retryOptions,
}) async {
  retryOptions ??= const RetryOptions(
    maxDelay: Duration(seconds: 5),
    maxAttempts: 3,
  );
  final Uri url = Uri.https('raw.githubusercontent.com', filePath);
  return retryOptions.retry(
    () async => await getUrl(url, httpClientProvider, log: log, timeout: timeout),
    retryIf: (Exception e) => e is HttpException,
  );
}

/// Return [String] of response from [url] if status is [HttpStatus.ok].
///
/// If [url] returns [HttpStatus.notFound] throw [NotFoundException].
/// Otherwise, throws [HttpException].
FutureOr<String> getUrl(
  Uri url,
  HttpClientProvider httpClientProvider, {
  Logging log,
  Duration timeout = const Duration(seconds: 5),
}) async {
  final HttpClient client = httpClientProvider();
  try {
    final HttpClientRequest clientRequest = await client.getUrl(url).timeout(timeout);
    final HttpClientResponse clientResponse = await clientRequest.close().timeout(timeout);
    final int status = clientResponse.statusCode;

    if (status == HttpStatus.ok) {
      return await utf8.decoder.bind(clientResponse).join();
    } else if (status == HttpStatus.notFound) {
      throw NotFoundException('HTTP $status: $url');
    } else {
      log?.warning('HTTP $status: $url');
      throw HttpException('HTTP $status: $url');
    }
  } finally {
    client.close(force: true);
  }
}

/// Gets supported branch list of `flutter/flutter` via GitHub http request.
Future<Uint8List> getBranches(
  HttpClientProvider httpClientProvider,
  Logging log, {
  RetryOptions retryOptions,
}) async {
  String content;
  try {
    content = await githubFileContent(
      '/flutter/cocoon/master/app_dart/dev/branches.txt',
      httpClientProvider: httpClientProvider,
      log: log,
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

Future<RepositorySlug> repoNameForBuilder(List<LuciBuilder> builders, String builderName) async {
  final LuciBuilder builderConfig = builders.firstWhere(
    (LuciBuilder builder) => builder.name == builderName,
    orElse: () => const LuciBuilder(repo: '', name: '', flaky: false),
  );
  final String repoName = builderConfig.repo;
  // If there is no builder config for the builderName then we
  // return null. This is to allow the code calling this method
  // to skip changes that depend on builder configurations.
  if (repoName.isEmpty) {
    return null;
  }
  return RepositorySlug('flutter', repoName);
}

/// Returns LUCI builders based on [bucket] and [slug].
///
/// For `try` case with [commitSha], builders are returned based on try_builders.json config file in
/// the corresponding [commitSha].
///
/// For `prod` case, builders are returned based on prod_builders.json config file from `master`.
Future<List<LuciBuilder>> getLuciBuilders(
  HttpClientProvider httpClientProvider,
  Logging log,
  RepositorySlug slug,
  String bucket, {
  String commitSha = 'master',
  RetryOptions retryOptions,
}) async {
  const Map<String, String> repoFilePathPrefix = <String, String>{
    'flutter': 'dev',
    'engine': 'ci/dev',
    'cocoon': 'dev',
    'plugins': '.ci/dev',
    'packages': 'dev'
  };
  final String filePath = '${slug.owner}/${slug.name}/$commitSha/${repoFilePathPrefix[slug.name]}';
  final String fileName = bucket == 'try' ? 'try_builders.json' : 'prod_builders.json';
  final String builderConfigPath = '$filePath/$fileName';
  String builderContent;
  try {
    builderContent = await githubFileContent(
      builderConfigPath,
      httpClientProvider: httpClientProvider,
      log: log,
      retryOptions: retryOptions,
    );
  } on NotFoundException {
    builderContent = '{"builders":[]}';
  } on HttpException catch (_, e) {
    log.warning('githubFileContent failed to get $builderConfigPath: $e');
    builderContent = '{"builders":[]}';
  }

  Map<String, dynamic> builderMap;
  builderMap = json.decode(builderContent) as Map<String, dynamic>;
  final List<dynamic> builderList = builderMap['builders'] as List<dynamic>;
  final List<LuciBuilder> builders = builderList
      .map((dynamic builder) => LuciBuilder.fromJson(builder as Map<String, dynamic>))
      .where((LuciBuilder element) => element.enabled ?? true)
      .toList();

  return builders;
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
Future<List<LuciBuilder>> getFilteredBuilders(List<LuciBuilder> builders, List<String> files) async {
  final List<LuciBuilder> filteredBuilders = <LuciBuilder>[];
  for (LuciBuilder builder in builders) {
    final List<String> globs = builder.runIf ?? <String>[''];
    // Handle case where [Target] initializes empty runif
    if (globs.isEmpty) {
      filteredBuilders.add(builder);
    }
    for (String glob in globs) {
      glob = glob.replaceAll('**', '[a-zA-Z_\/]?');
      glob = glob.replaceAll('*', '[a-zA-Z_\/]*');
      // If a file is found within a pre-set dir, the builder needs to run. No need to check further.
      final RegExp regExp = RegExp('^$glob');
      if (glob.isEmpty || files.any((String file) => regExp.hasMatch(file))) {
        filteredBuilders.add(builder);
        break;
      }
    }
  }
  return filteredBuilders;
}

Future<void> insertBigquery(
    String tableName, Map<String, dynamic> data, TabledataResourceApi tabledataResourceApi, Logging log) async {
  // Define const variables for [BigQuery] operations.
  const String projectId = 'flutter-dashboard';
  const String dataset = 'cocoon';
  final String table = tableName;
  final List<Map<String, Object>> requestRows = <Map<String, Object>>[];

  requestRows.add(<String, Object>{
    'json': data,
  });

  // Obtain [rows] to be inserted to [BigQuery].
  final TableDataInsertAllRequest request = TableDataInsertAllRequest.fromJson(<String, Object>{'rows': requestRows});

  try {
    await tabledataResourceApi.insertAll(request, projectId, dataset, table);
  } on ApiRequestError catch (error) {
    log.warning('Failed to add to BigQuery: $error');
  }
}

/// Validate test ownership defined in `testOwnersContenct` for tests configured in `ciYamlContent`.
List<String> validateOwnership(String ciYamlContent, String testOwnersContenct) {
  final List<String> noOwnerBuilders = <String>[];
  final YamlMap ciYaml = loadYaml(ciYamlContent) as YamlMap;
  final SchedulerConfig schedulerConfig = schedulerConfigFromYaml(ciYaml);
  for (Target target in schedulerConfig.targets) {
    final String builder = target.name;
    final String owner = getTestOwner(builder, getTypeForBuilder(builder, ciYaml), testOwnersContenct);
    print('$builder: $owner');
    if (owner == null) {
      noOwnerBuilders.add(builder);
    }
  }
  return noOwnerBuilders;
}

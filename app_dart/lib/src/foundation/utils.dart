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

import '../foundation/typedefs.dart';
import '../service/github_service.dart';
import '../service/luci.dart';

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
Future<String> remoteFileContent(
  HttpClientProvider branchHttpClientProvider,
  Logging log,
  GitHubBackoffCalculator gitHubBackoffCalculator,
  String filePath, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final Uri url = Uri.https('raw.githubusercontent.com', filePath);

  final HttpClient client = branchHttpClientProvider();
  try {
    // TODO(keyonghan): apply retry logic here to simply, https://github.com/flutter/flutter/issues/52427
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        final HttpClientRequest clientRequest = await client.getUrl(url).timeout(timeout);
        final HttpClientResponse clientResponse = await clientRequest.close().timeout(timeout);
        final int status = clientResponse.statusCode;

        if (status == HttpStatus.ok) {
          final String content = await utf8.decoder.bind(clientResponse).join();
          return content;
        } else {
          log.warning('Attempt to download $filePath failed (HTTP $status)');
        }
      } catch (error, stackTrace) {
        log.error('Attempt to download $filePath failed:\n$error\n$stackTrace');
      }
      await Future<void>.delayed(gitHubBackoffCalculator(attempt));
    }
  } finally {
    client.close(force: true);
  }
  log.error('GitHub not responding; giving up');
  return null;
}

/// Gets supported branch list of `flutter/flutter` via GitHub http request.
Future<Uint8List> getBranches(
    HttpClientProvider branchHttpClientProvider, Logging log, GitHubBackoffCalculator gitHubBackoffCalculator) async {
  String content = await remoteFileContent(
      branchHttpClientProvider, log, gitHubBackoffCalculator, '/flutter/cocoon/master/app_dart/dev/branches.txt');
  content ??= 'master';
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

/// Returns LUCI builders based on [bucket] and [repo].
///
/// Builder config is loaded from `$bucket_builders.json` at [ref] of [repo].
///
/// If [bucket] is try, [prNumber] is used to filter the builder list to only the affected
/// builders based on the [run_if] config property.
Future<List<LuciBuilder>> getLuciBuilders(GithubService githubService, HttpClientProvider luciHttpClientProvider,
    GitHubBackoffCalculator gitHubBackoffCalculator, Logging log, RepositorySlug slug, String bucket,
    {int prNumber, String ref = 'master'}) async {
  const Map<String, String> repoFilePathPrefix = <String, String>{
    'flutter': 'dev',
    'engine': 'ci/dev',
    'cocoon': 'dev',
    'plugins': '.ci/dev',
    'packages': 'dev'
  };
  final String filePath = '${slug.name}/$ref/${repoFilePathPrefix[slug.name]}/';
  final String fileName = bucket == 'try' ? 'try_builders.json' : 'prod_builders.json';
  String builderContent =
      await remoteFileContent(luciHttpClientProvider, log, gitHubBackoffCalculator, '/flutter/$filePath$fileName');
  builderContent ??= '{"builders":[]}';
  final Map<String, dynamic> builderMap = json.decode(builderContent) as Map<String, dynamic>;
  final List<dynamic> builderList = builderMap['builders'] as List<dynamic>;
  final List<LuciBuilder> builders = builderList
      .map((dynamic builder) => LuciBuilder.fromJson(builder as Map<String, dynamic>))
      .where((LuciBuilder element) => element.enabled ?? true)
      .toList();

  if (bucket == 'prod') {
    return builders;
  }

  final List<String> files = await githubService.listFiles(slug, prNumber);
  return await getFilteredBuilders(builders, files);
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

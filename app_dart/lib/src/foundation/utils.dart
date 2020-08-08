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

Future<String> remoteFileContent(HttpClientProvider branchHttpClientProvider, Logging log,
    GitHubBackoffCalculator gitHubBackoffCalculator, String filePath) async {
  final Uri url = Uri.https('raw.githubusercontent.com', filePath);

  final HttpClient client = branchHttpClientProvider();
  try {
    // TODO(keyonghan): apply retry logic here to simply, https://github.com/flutter/flutter/issues/52427
    for (int attempt = 0; attempt < 3; attempt++) {
      final HttpClientRequest clientRequest = await client.getUrl(url);

      try {
        final HttpClientResponse clientResponse = await clientRequest.close();
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

Future<RepositorySlug> repoNameForBuilder(List<Map<String, dynamic>> builders, String builderName) async {
  final Map<String, dynamic> builderConfig = builders.firstWhere(
    (Map<String, dynamic> builder) => builder['name'] == builderName,
    orElse: () => <String, String>{'repo': ''},
  );
  final String repoName = builderConfig['repo'] as String;
  // If there is no builder config for the builderName then we
  // return null. This is to allow the code calling this method
  // to skip changes that depend on builder configurations.
  if (repoName.isEmpty) {
    return null;
  }
  return RepositorySlug('flutter', repoName);
}

/// Gets supported luci builders based on [bucket] via GitHub http request.
///
// TODO(keyonghan): to be removed when APIs are updated to call getRepoBuilders, https://github.com/flutter/flutter/issues/62429
Future<List<Map<String, dynamic>>> getBuilders(HttpClientProvider branchHttpClientProvider, Logging log,
    GitHubBackoffCalculator gitHubBackoffCalculator, String bucket) async {
  final String filename = bucket == 'try' ? 'luci_try_builders.json' : 'luci_prod_builders.json';
  String builderContent = await remoteFileContent(
      branchHttpClientProvider, log, gitHubBackoffCalculator, '/flutter/cocoon/master/app_dart/dev/$filename');
  builderContent ??= '{"builders":[]}';
  Map<String, dynamic> builderMap;
  builderMap = json.decode(builderContent) as Map<String, dynamic>;
  final List<dynamic> builderList = builderMap['builders'] as List<dynamic>;
  return builderList.map((dynamic builder) => builder as Map<String, dynamic>).toList();
}

/// Gets supported luci builders based on [bucket] and [repo] via GitHub http request.
Future<List<Map<String, dynamic>>> getRepoBuilders(HttpClientProvider branchHttpClientProvider, Logging log,
    GitHubBackoffCalculator gitHubBackoffCalculator, String bucket, String repo) async {
  final String filePath = repo == 'engine' ? '$repo/master/ci/dev/' : '$repo/master/dev/';
  final String fileName = bucket == 'try' ? 'try_builders.json' : 'prod_builders.json';
  String builderContent =
      await remoteFileContent(branchHttpClientProvider, log, gitHubBackoffCalculator, '/flutter/$filePath$fileName');
  builderContent ??= '{"builders":[]}';
  Map<String, dynamic> builderMap;
  builderMap = json.decode(builderContent) as Map<String, dynamic>;
  final List<dynamic> builderList = builderMap['builders'] as List<dynamic>;
  return builderList.map((dynamic builder) => builder as Map<String, dynamic>).toList();
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
  } on ApiRequestError {
    log.warning('Failed to add build status to BigQuery: $ApiRequestError');
  }
}

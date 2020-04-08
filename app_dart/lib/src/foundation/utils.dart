// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:appengine/appengine.dart';
import 'package:cocoon_service/src/service/github_service.dart';
import 'package:github/server.dart';

import '../datastore/cocoon_config.dart';
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

Future<List<String>> loadBranchRegExps(
    HttpClientProvider branchHttpClientProvider,
    Logging log,
    GitHubBackoffCalculator gitHubBackoffCalculator) async {
  const String path = '/flutter/cocoon/master/app_dart/dev/branch_regexps.txt';
  final Uri url = Uri.https('raw.githubusercontent.com', path);

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
          final List<String> branches = content
              .split('\n')
              .map((String branch) => branch.trim())
              .toList();
          branches.removeWhere((String branch) => branch.isEmpty);
          return branches;
        } else {
          log.warning(
              'Attempt to download branch_regexps.txt failed (HTTP $status)');
        }
      } catch (error, stackTrace) {
        log.error(
            'Attempt to download branch_regexps.txt failed:\n$error\n$stackTrace');
      }
      await Future<void>.delayed(gitHubBackoffCalculator(attempt));
    }
  } finally {
    client.close(force: true);
  }
  log.error('GitHub not responding; giving up');
  return <String>['master'];
}

Future<List<String>> getBranchList(
    Config config,
    HttpClientProvider branchHttpClientProvider,
    Logging log,
    GitHubBackoffCalculator gitHubBackoffCalculator) async {
  final List<String> regExps = await loadBranchRegExps(
      branchHttpClientProvider, log, gitHubBackoffCalculator);
  // TODO(keyonghan): save this list in cocoon config datastore, https://github.com/flutter/flutter/issues/54297
  const List<String> branchList = <String>[
    'master',
    'flutter-1.17-candidate.0',
    'flutter-1.17-candidate.1',
    'flutter-1.17-candidate.2',
    'flutter-1.17-candidate.3',
    'flutter-1.17-candidate.4',
    'flutter-1.17-candidate.5',
    'flutter-1.18-candidate.0',
    'flutter-1.18-candidate.1',
    'flutter-1.18-candidate.2',
    'flutter-1.18-candidate.3',
    'flutter-1.18-candidate.4',
    'v1.12.13-hotfixes'
  ];
  final List<String> branches = <String>[];

  for (String branch in branchList) {
    if (!regExps.any((String regExp) => RegExp(regExp).hasMatch(branch))) {
      continue;
    }
    branches.add(branch);
  }
  return branches;
}

Future<List<Branch>> getBranches(
    Config config,
    HttpClientProvider branchHttpClientProvider,
    Logging log,
    GitHubBackoffCalculator gitHubBackoffCalculator) async {
  final GithubService githubService = await config.createGithubService();
  final GitHub github = githubService.github;
  const RepositorySlug slug = RepositorySlug('flutter', 'flutter');
  final Stream<Branch> branchList = github.repositories.listBranches(slug);
  final List<String> regExps = await loadBranchRegExps(
      branchHttpClientProvider, log, gitHubBackoffCalculator);
  final List<Branch> branches = <Branch>[];

  await for (Branch branch in branchList) {
    if (!regExps.any((String regExp) => RegExp(regExp).hasMatch(branch.name))) {
      continue;
    }
    branches.add(branch);
  }
  return branches;
}

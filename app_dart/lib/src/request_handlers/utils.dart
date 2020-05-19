// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:appengine/appengine.dart';

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

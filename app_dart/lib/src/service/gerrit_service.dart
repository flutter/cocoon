// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' as convert;
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:retry/retry.dart';

import 'logging.dart';

class RetryException implements Exception {}

/// Communicates with gerrit APIs https://gerrit-review.googlesource.com/Documentation/rest-api-projects.html
/// to get information about projects hosted in Git on Borg.
class GerritService {
  GerritService({http.Client? httpClient}) : httpClient = httpClient ?? http.Client();

  final http.Client httpClient;

  /// Gets the branches from a remote git repository using the gerrit APIs.
  Future<List<String>> branches(String repo, String project, String subString) async {
    final Uri url = Uri.https(repo, 'projects/$project/branches', <String, dynamic>{'m': subString});
    final http.Response response;
    const RetryOptions retryOptions = RetryOptions(maxAttempts: 3);

    response = await retryOptions.retry(
      () async {
        final http.Response tempResponse = await httpClient.get(url).timeout(const Duration(seconds: 5));
        if (tempResponse.statusCode != HttpStatus.ok) {
          log.warning('Error calling gerrit API ${tempResponse.body}');
          throw RetryException();
        }
        return tempResponse;
      },
      retryIf: (Exception e) => e is SocketException || e is TimeoutException || e is RetryException,
    );

    final List<String> branches = <String>[];

    /// To prevent against Cross Site Script Inclusion (XSSI) attacks, the JSON response body starts with a magic prefix line that
    /// must be stripped before feeding the rest of the response body to a JSON parser. The magic prefix is ")]}'".
    final String jsonBody = response.body.replaceRange(0, 4, '');
    final Iterable<Map<String, dynamic>> json =
        (convert.jsonDecode(jsonBody) as List<dynamic>).map((dynamic e) => e as Map<String, dynamic>);
    for (Map<String, dynamic> element in json) {
      branches.add(element['ref'] as String);
    }

    return branches;
  }
}

// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' as convert;

import 'package:http/http.dart' as http;

import 'logging.dart';

class GerritService {
  GerritService({http.Client? httpClient}) : httpClient = httpClient ?? http.Client();

  final http.Client httpClient;

  /// Gets the branches from a remote git repository using the gerrit APIs.
  Future<List<String>> branches(String repo, String project, String prefix) async {
    final Uri url = Uri.https(repo, 'projects/$project/branches', <String, dynamic>{'m': prefix});
    final http.Response response = await httpClient.get(url);
    final List<String> result = <String>[];
    if (response.statusCode == 200) {
      final String jsonBody = response.body.replaceRange(0, 4, '');
      final Iterable<Map<String, dynamic>> json =
          (convert.jsonDecode(jsonBody) as List<dynamic>).map((dynamic e) => e as Map<String, dynamic>);
      for (Map<String, dynamic> element in json) {
        result.add(element['ref'] as String);
      }
    } else {
      log.warning('Error calling gerrit API ${response.body}');
    }
    return result;
  }
}

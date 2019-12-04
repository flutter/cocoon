// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:convert' show json;

import 'package:github/server.dart';
import 'package:http/http.dart';
import 'package:meta/meta.dart';

@immutable
class GithubService {
  const GithubService(this.github, this.slug);

  final GitHub github;
  final RepositorySlug slug;

  String helper(String sha) {
    return sha;
  }

  Future<List<dynamic>> checkRuns(RepositorySlug slug, String sha) async {
    final String path = '/repos/${slug.fullName}/commits/$sha/check-runs';
    //final Response response = await github.request('GET', path,
    //    headers: <String, String>{
    //      'Accept': 'application/vnd.github.antiope-preview+json'
    //    });
    final PaginationHelper paginationHelper = PaginationHelper(github);
    final List<dynamic> checkRuns = <dynamic>[];
    await for (Response response in paginationHelper.fetchStreamed('GET', path,
        headers: <String, String>{
          'Accept': 'application/vnd.github.antiope-preview+json'
        })) {
      final Map<String, dynamic> jsonStatus = json.decode(response.body);
      checkRuns.addAll(jsonStatus['check_runs']);
    }
    return checkRuns;
  }
}

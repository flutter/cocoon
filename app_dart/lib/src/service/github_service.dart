// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:convert' show json;

import 'package:github/server.dart';
import 'package:http/http.dart';

class GithubService {
  const GithubService(this.github);

  final GitHub github;

  /// Lists the commits of the provided repository [slug] and [branch].
  Future<List<RepositoryCommit>> listCommits(
      RepositorySlug slug, String branch) async {
    const Duration time = Duration(hours: 1);
    ArgumentError.checkNotNull(slug);
    final PaginationHelper paginationHelper = PaginationHelper(github);

    final List<Map<String, dynamic>> commits = <Map<String, dynamic>>[];
    await for (Response response in paginationHelper.fetchStreamed(
      'GET',
      '/repos/${slug.fullName}/commits',
      params: <String, dynamic>{
        'sha': branch,
        'since': DateTime.now().toUtc().subtract(time).toIso8601String()
      },
    )) {
      commits.addAll((json.decode(response.body) as List<dynamic>)
          .cast<Map<String, dynamic>>());
    }

    return commits.map((dynamic commit) {
      return RepositoryCommit()
        ..sha = commit['sha'] as String
        ..author = (User()
          ..login = commit['author']['login'] as String
          ..avatarUrl = commit['author']['avatar_url'] as String)
        ..commit = (GitCommit()
          ..committer = (GitCommitUser(
              commit['commit']['author']['name'] as String,
              commit['commit']['author']['email'] as String,
              DateTime.parse(commit['commit']['author']['date'] as String))));
    }).toList();
  }
}

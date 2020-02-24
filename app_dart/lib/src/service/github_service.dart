// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:convert' show json;

import 'package:github/server.dart';
import 'package:http/http.dart';

class GithubService {
  const GithubService(this.github);

  final GitHub github;

  Future<List<dynamic>> checkRuns(String sha) async {
    const RepositorySlug slug = RepositorySlug('flutter', 'flutter');
    final String path = '/repos/${slug.fullName}/commits/$sha/check-runs';
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

  /// Lists the commits of the provided repository [slug] and [branch].
  Future<List<RepositoryCommit>> listCommits(
      RepositorySlug slug, String branch) async {
    const Duration time = Duration(days: 30);
    ArgumentError.checkNotNull(slug);
    final PaginationHelper paginationHelper = PaginationHelper(github);

    final List<dynamic> commits = <dynamic>[];
    await for (Response response in paginationHelper.fetchStreamed(
      'GET',
      '/repos/${slug.fullName}/commits',
      params: <String, dynamic>{
        'sha': branch,
        'since': DateTime.now().subtract(time).toIso8601String()
      },
    )) {
      commits.addAll(json.decode(response.body));
    }

    return commits.map((dynamic commit) {
      return RepositoryCommit()
        ..sha = commit['sha']
        ..author = (User()
          ..login = commit['author']['login']
          ..avatarUrl = commit['author']['avatar_url'])
        ..commit = (GitCommit()
          ..committer = (GitCommitUser(
              commit['commit']['author']['name'],
              commit['commit']['author']['email'],
              DateTime.parse(commit['commit']['author']['date']))));
    }).toList();
  }
}

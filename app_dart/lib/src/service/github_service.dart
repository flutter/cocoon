// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' show json;

import 'package:github/github.dart';
import 'package:http/http.dart';

import '../datastore/cocoon_config.dart';

class GithubService {
  const GithubService(this.github);

  final GitHub github;

  /// Lists the commits of the provided repository [slug] and [branch].
  Future<List<RepositoryCommit>> listCommits(RepositorySlug slug, String branch,
      int lastCommitTimestampMills, Config config) async {
    ArgumentError.checkNotNull(slug);
    final PaginationHelper paginationHelper = PaginationHelper(github);

    /// Return only one page when this is a new branch. Otherwise it will
    /// return all commits prior to this release branch commit, leading to
    /// heavy workload.
    int pages;
    if (lastCommitTimestampMills == 0) {
      pages = 1;
    }

    List<Map<String, dynamic>> commits = <Map<String, dynamic>>[];

    /// [lastCommitTimestamp+1] excludes last commit itself.
    await for (Response response in paginationHelper.fetchStreamed(
      'GET',
      '/repos/${slug.fullName}/commits',
      params: <String, dynamic>{
        'sha': branch,
        'since':
            DateTime.fromMillisecondsSinceEpoch(lastCommitTimestampMills + 1)
                .toUtc()
                .toIso8601String(),
      },
      pages: pages,
    )) {
      commits.addAll((json.decode(response.body) as List<dynamic>)
          .cast<Map<String, dynamic>>());
    }

    /// Take the latest single commit for a new release branch.
    if (lastCommitTimestampMills == 0) {
      commits = commits.take(1).toList();
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

  Future<List<PullRequest>> listPullRequests(
      RepositorySlug slug, String branch) async {
    ArgumentError.checkNotNull(slug);
    final PaginationHelper paginationHelper = PaginationHelper(github);

    final List<Map<String, dynamic>> pullRequests = <Map<String, dynamic>>[];
    await for (Response response in paginationHelper.fetchStreamed(
      'GET',
      '/repos/${slug.fullName}/pulls',
      params: <String, dynamic>{
        'base': branch,
        'direction': 'desc',
        'sort': 'created',
        'state': 'open',
      },
    )) {
      pullRequests.addAll((json.decode(response.body) as List<dynamic>)
          .cast<Map<String, dynamic>>());
    }

    return pullRequests.map((dynamic commit) {
      return PullRequest()
        ..number = commit['number'] as int
        ..head = (PullRequestHead()..sha = commit['head']['sha'] as String);
    }).toList();
  }
}

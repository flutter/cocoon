// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' show json;

import 'package:github/github.dart';
import 'package:http/http.dart';

class GithubService {
  const GithubService(this.github);

  final GitHub github;
  static final Map<String, String> headers = <String, String>{'Accept': 'application/vnd.github.groot-preview+json'};

  /// Lists commits of the provided repository [slug] and [branch]. When
  /// [lastCommitTimestampMills] equals 0, it means a new release branch is
  /// found and only the branched commit will be returned for now, though the
  /// rare case that multiple commits exist. For other cases, it returns all
  /// newer commits since [lastCommitTimestampMills].
  Future<List<RepositoryCommit>> listCommits(RepositorySlug slug, String branch, int lastCommitTimestampMills) async {
    ArgumentError.checkNotNull(slug);
    final PaginationHelper paginationHelper = PaginationHelper(github);

    /// The [pages] defines the number of pages of returned http request
    /// results. Return only one page when this is a new branch. Otherwise
    ///  it will return all commits prior to this release branch commit,
    /// leading to heavy workload.
    int pages;
    if (lastCommitTimestampMills == 0) {
      pages = 1;
    }

    List<Map<String, dynamic>> commits = <Map<String, dynamic>>[];

    /// [lastCommitTimestamp+1] excludes last commit itself.
    /// Github api url: https://developer.github.com/v3/repos/commits/#list-commits
    await for (Response response in paginationHelper.fetchStreamed(
      'GET',
      '/repos/${slug.fullName}/commits',
      params: <String, dynamic>{
        'sha': branch,
        'since': DateTime.fromMillisecondsSinceEpoch(lastCommitTimestampMills + 1).toUtc().toIso8601String(),
      },
      pages: pages,
      headers: headers,
    )) {
      commits.addAll((json.decode(response.body) as List<dynamic>).cast<Map<String, dynamic>>());
    }

    /// When a release branch is first detected only the most recent commit would be needed.
    ///
    /// If for the worst case, a new release branch consists of a useful cherry pick commit
    /// which should be considered as well, here is the todo.
    // TODO(keyonghan): https://github.com/flutter/flutter/issues/59275
    if (lastCommitTimestampMills == 0) {
      commits = commits.take(1).toList();
    }

    return commits.map<RepositoryCommit>((Map<String, dynamic> commit) {
      return RepositoryCommit()
        ..sha = commit['sha'] as String
        ..author = (User()
          ..login = commit['author']['login'] as String
          ..avatarUrl = commit['author']['avatar_url'] as String)
        ..commit = (GitCommit()
          ..message = commit['commit']['message'] as String
          ..committer = (GitCommitUser(
              commit['commit']['author']['name'] as String,
              commit['commit']['author']['email'] as String,
              DateTime.parse(commit['commit']['author']['date'] as String))));
    }).toList();
  }

  Future<List<PullRequest>> listPullRequests(RepositorySlug slug, String branch) async {
    ArgumentError.checkNotNull(slug);
    final PaginationHelper paginationHelper = PaginationHelper(github);

    final List<Map<String, dynamic>> pullRequests = <Map<String, dynamic>>[];

    headers['Authorization'] = 'Bearer ${github.auth.token}';
    await for (Response response in paginationHelper.fetchStreamed(
      'GET',
      '/repos/${slug.fullName}/pulls',
      params: <String, dynamic>{
        'base': branch,
        'direction': 'desc',
        'sort': 'created',
        'state': 'open',
      },
      headers: headers,
    )) {
      pullRequests.addAll((json.decode(response.body) as List<dynamic>).cast<Map<String, dynamic>>());
    }

    return pullRequests.map((dynamic commit) {
      return PullRequest()
        ..number = commit['number'] as int
        ..head = (PullRequestHead()..sha = commit['head']['sha'] as String);
    }).toList();
  }
}

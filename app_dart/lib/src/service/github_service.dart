// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:math';

import 'package:github/github.dart';
import 'package:http/http.dart';

import '../service/logging.dart';

class GithubService {
  GithubService(this.github);

  final GitHub github;
  static final Map<String, String> headers = <String, String>{'Accept': 'application/vnd.github.groot-preview+json'};
  static const String kRefsPrefix = 'refs/heads/';

  /// Return commits unique to [branch] for the repository [slug].
  ///
  /// When [lastCommitTimestampMills] equals 0, it means a new release branch is
  /// found and only the branched commit will be returned for now, though the
  /// rare case that multiple commits exist. For other cases, it returns all
  /// newer commits since [lastCommitTimestampMills].
  Future<List<RepositoryCommit>> listBranchedCommits(
    RepositorySlug slug,
    String branch,
    int? lastCommitTimestampMills,
  ) async {
    ArgumentError.checkNotNull(slug);
    final PaginationHelper paginationHelper = PaginationHelper(github);

    /// The [pages] defines the number of pages of returned http request
    /// results. Return only one page when this is a new branch. Otherwise
    ///  it will return all commits prior to this release branch commit,
    /// leading to heavy workload.
    int? pages;
    if (lastCommitTimestampMills == null || lastCommitTimestampMills == 0) {
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
        'since': DateTime.fromMillisecondsSinceEpoch((lastCommitTimestampMills ?? 0) + 1).toUtc().toIso8601String(),
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
        ..sha = commit['sha'] as String?
        ..author = (User()
          ..login = commit['author']['login'] as String?
          ..avatarUrl = commit['author']['avatar_url'] as String?)
        ..commit = (GitCommit()
          ..message = commit['commit']['message'] as String?
          ..committer = (GitCommitUser(
            commit['commit']['author']['name'] as String?,
            commit['commit']['author']['email'] as String?,
            DateTime.parse(commit['commit']['author']['date'] as String),
          )));
    }).toList();
  }

  static RepositoryCommit _fromMap(Map<String, dynamic> commit) {
    return RepositoryCommit()
        ..sha = commit['sha'] as String?
        ..author = (User()
          ..login = commit['author']['login'] as String?
          ..avatarUrl = commit['author']['avatar_url'] as String?)
        ..commit = (GitCommit()
          ..message = commit['commit']['message'] as String?
          ..committer = (GitCommitUser(
            commit['commit']['author']['name'] as String?,
            commit['commit']['author']['email'] as String?,
            DateTime.parse(commit['commit']['author']['date'] as String),
          )));
  }

  /// Return a single commit for the repository [slug].
  Future<RepositoryCommit> getSingleCommit(
    RepositorySlug slug,
    String sha,
  ) async {
    ArgumentError.checkNotNull(slug);
    log.fine("Attempting to get json");
    return github.getJSON<Map<String, dynamic>, RepositoryCommit>(
      '/repos/${slug.fullName}/commits/$sha',
      convert: (Map<String, dynamic> i) => _fromMap(i),
    );
  }

  /// List pull requests in the repository.
  Future<List<PullRequest>> listPullRequests(RepositorySlug slug, String? branch) {
    ArgumentError.checkNotNull(slug);
    return github.pullRequests
        .list(
          slug,
          base: branch,
          direction: 'desc',
          sort: 'created',
          state: 'open',
        )
        .toList();
  }

  /// Creates a pull request against the `baseRef` in the `slug` repository.
  ///
  /// The `entries` contains the file changes in the created pull request. This
  /// method creates a branch in the current user's forked repository to create
  /// the pull request. The current user must have a forked repository from the
  /// targeted slug, and the targeted slug must not be belong to current user.
  Future<PullRequest> createPullRequest(
    RepositorySlug slug, {
    required String title,
    String? body,
    String? commitMessage,
    required GitReference baseRef,
    List<CreateGitTreeEntry>? entries,
  }) async {
    ArgumentError.checkNotNull(slug);
    ArgumentError.checkNotNull(title);

    final RepositorySlug clientSlug = await _getCurrentUserSlug(slug.name);
    final GitTree tree = await github.git.createTree(clientSlug, CreateGitTree(entries, baseTree: baseRef.object!.sha));
    final CurrentUser currentUser = (await _getCurrentUser())!;
    final GitCommitUser commitUser = GitCommitUser(currentUser.name, currentUser.email, DateTime.now());
    final GitCommit commit = await github.git.createCommit(
      clientSlug,
      CreateGitCommit(
        commitMessage,
        tree.sha,
        parents: <String?>[baseRef.object!.sha],
        author: commitUser,
        committer: commitUser,
      ),
    );
    final GitReference headRef =
        await github.git.createReference(clientSlug, '$kRefsPrefix${_generateNewRef()}', commit.sha);
    return github.pullRequests.create(
      slug,
      CreatePullRequest(title, '${clientSlug.owner}:${headRef.ref}', baseRef.ref, body: body),
    );
  }

  /// Assigns a reviewer to the pull request in the repository.
  ///
  /// The `reviewer` contains the github login of the reviewer.
  Future<void> assignReviewer(
    RepositorySlug slug, {
    int? pullRequestNumber,
    String? reviewer,
  }) async {
    const JsonEncoder encoder = JsonEncoder();
    await github.postJSON<Map<String, dynamic>, PullRequest>(
      '/repos/${slug.fullName}/pulls/$pullRequestNumber/requested_reviewers',
      convert: (Map<String, dynamic> i) => PullRequest.fromJson(i),
      body: encoder.convert(<String, dynamic>{
        'reviewers': <String?>[reviewer],
      }),
    );
  }

  /// Adds labels to an issue.
  ///
  /// A pull request is an issue. This works for pull requests as well.
  Future<List<IssueLabel>> addIssueLabels(
    RepositorySlug slug,
    int issueNumber,
    List<String> labels,
  ) async {
    ArgumentError.checkNotNull(slug);
    ArgumentError.checkNotNull(issueNumber);
    ArgumentError.checkNotNull(labels);
    return github.issues.addLabelsToIssue(slug, issueNumber, labels);
  }

  /// Retrieves issues from the repository.
  ///
  /// Uses the `labels` to return the issues that have the labels.
  ///
  /// The `state` can be set `open`, `closed, or `all`. If it is set to `open`,
  /// this method only returns issues that are currently open. If it is set to
  /// `closed`, this method returns issues that are currently closed. The `all`
  /// returns both closed and open issues. Defaults to `open`.
  Future<List<Issue>> listIssues(
    RepositorySlug slug, {
    List<String>? labels,
    String state = 'open',
  }) {
    ArgumentError.checkNotNull(slug);
    return github.issues.listByRepo(slug, labels: labels, state: state).toList();
  }

  /// Get an issue with the issue number
  Future<Issue>? getIssue(
    RepositorySlug slug, {
    required int issueNumber,
  }) {
    ArgumentError.checkNotNull(slug);
    ArgumentError.checkNotNull(issueNumber);
    return github.issues.get(slug, issueNumber);
  }

  /// Assign the issue to the assignee.
  Future<void> assignIssue(
    RepositorySlug slug, {
    required int issueNumber,
    required String assignee,
  }) async {
    ArgumentError.checkNotNull(slug);
    ArgumentError.checkNotNull(issueNumber);
    ArgumentError.checkNotNull(assignee);
    await github.issues.edit(slug, issueNumber, IssueRequest(assignee: assignee));
  }

  Future<Issue> createIssue(
    RepositorySlug slug, {
    String? title,
    String? body,
    List<String>? labels,
    String? assignee,
  }) async {
    ArgumentError.checkNotNull(slug);
    return github.issues.create(
      slug,
      IssueRequest(title: title, body: body, labels: labels, assignee: assignee),
    );
  }

  Future<IssueComment?> createComment(
    RepositorySlug slug, {
    required int issueNumber,
    required String body,
  }) async {
    ArgumentError.checkNotNull(slug);
    ArgumentError.checkNotNull(issueNumber);
    return github.issues.createComment(slug, issueNumber, body);
  }

  Future<List<IssueLabel>> replaceLabelsForIssue(
    RepositorySlug slug, {
    required int issueNumber,
    required List<String> labels,
  }) async {
    ArgumentError.checkNotNull(slug);
    ArgumentError.checkNotNull(issueNumber);
    final Response response = await github.request(
      'PUT',
      '/repos/${slug.fullName}/issues/$issueNumber/labels',
      body: GitHubJson.encode(labels),
    );
    final List<dynamic> body = jsonDecode(response.body) as List<dynamic>;
    return body.map((dynamic it) => IssueLabel.fromJson(it as Map<String, dynamic>)).toList();
  }

  /// Returns changed files for a [PullRequest].
  ///
  /// See more:
  ///   * https://developer.github.com/v3/pulls/#list-pull-requests-files
  Future<List<String>> listFiles(PullRequest pullRequest) async {
    final List<PullRequestFile> files =
        await github.pullRequests.listFiles(pullRequest.base!.repo!.slug(), pullRequest.number!).toList();
    log.fine('List of files: $files');
    return files.map((PullRequestFile file) {
      return file.filename!;
    }).toList();
  }

  /// Gets the file content as UTF8 string of the file specified by the `path`
  /// in the repository.
  Future<String> getFileContent(RepositorySlug slug, String path, {String? ref}) async {
    ArgumentError.checkNotNull(slug);
    ArgumentError.checkNotNull(path);
    final RepositoryContents contents = await github.repositories.getContents(slug, path, ref: ref);
    if (!contents.isFile) {
      throw 'The path $path should point to a file, but it is not!';
    }
    final String content = utf8.decode(base64.decode(contents.file!.content!.replaceAll('\n', '')));
    return content;
  }

  /// Gets the reference of a specific branch in the repository.
  Future<GitReference> getReference(RepositorySlug slug, String ref) {
    ArgumentError.checkNotNull(slug);
    ArgumentError.checkNotNull(ref);
    return github.git.getReference(slug, ref);
  }

  /// Returns JSON of the current GitHub API quota usage.
  ///
  /// This does not consume any API usage.
  ///
  /// Reference:
  ///   * https://docs.github.com/en/rest/reference/rate-limit
  Future<RateLimit> getRateLimit() => github.misc.getRateLimit();

  CurrentUser? _currentUser;

  Future<CurrentUser?> _getCurrentUser() async {
    _currentUser ??= await github.users.getCurrentUser();
    return _currentUser;
  }

  Future<RepositorySlug> _getCurrentUserSlug(String repository) async {
    return RepositorySlug((await _getCurrentUser())!.login!, repository);
  }

  String _generateNewRef() {
    const String chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    final Random rnd = Random();
    return String.fromCharCodes(Iterable<int>.generate(10, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }

  /// Returns a [List] of [Issue]s that match the given [query].
  ///
  /// The GitHub package uses the [Issue] object for both issue results and PRs.
  ///
  /// Reference:
  ///   * https://docs.github.com/en/rest/search?apiVersion=2022-11-28#search-issues-and-pull-requests
  ///   * https://docs.github.com/en/search-github/searching-on-github/searching-issues-and-pull-requests
  Future<List<Issue>> searchIssuesAndPRs(
    RepositorySlug slug,
    String query, {
    String? sort,
    int pages = 2,
  }) {
    return github.search
        .issues(
          Uri.encodeComponent('$query repo:${slug.fullName}'),
          sort: sort,
          pages: pages,
        )
        .toList();
  }

  /// Retrieves a pull request with the given [number].
  ///
  /// Reference:
  ///   * https://docs.github.com/en/rest/pulls/pulls?apiVersion=2022-11-28#get-a-pull-request
  Future<PullRequest> getPullRequest(RepositorySlug slug, int number) async {
    return github.pullRequests.get(slug, number);
  }
}

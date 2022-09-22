// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:auto_submit/service/github_service.dart';
import 'package:github/github.dart';
import 'package:shelf/src/response.dart';

import '../../utilities/mocks.dart';

/// A fake GithubService implementation.
class FakeGithubService implements GithubService {
  FakeGithubService({
    MockGitHub? client,
    String? checkRunsMock,
    String? commitMock,
    String? pullRequest,
    String? compareTwoCommitsMock,
    String? successMergeMock,
    String? createCommentMock,
    String? pullRequestMergeMock,
  }) : github = client ?? MockGitHub();

  @override
  final MockGitHub github;

  String? checkRunsMock;
  String? commitMock;
  PullRequest? pullRequestMock;
  String? compareTwoCommitsMock;
  String? successMergeMock;
  String? createCommentMock;
  String? pullRequestMergeMock;
  String? pullRequestFilesJsonMock;
  Issue? githubIssueMock;

  bool throwOnCreateIssue = false;

  /// Setting either of these flags to true will pop the front element from the
  /// list. Setting either to false will just return the non list version from
  /// the appropriate method.
  bool usePullRequestList = false;
  bool usePullRequestFilesList = false;

  List<String?> pullRequestFilesMockList = [];
  List<PullRequest?> pullRequestMockList = [];

  IssueComment? issueComment;
  bool useRealComment = false;
  bool labelRemoved = false;

  bool compareReturnValue = false;
  bool skipRealCompare = false;

  set checkRunsData(String? checkRunsMock) {
    this.checkRunsMock = checkRunsMock;
  }

  set commitData(String? commitMock) {
    this.commitMock = commitMock;
  }

  set pullRequestData(PullRequest? pullRequestMock) {
    this.pullRequestMock = pullRequestMock;
  }

  set compareTwoCommitsData(String? compareTwoCommitsMock) {
    this.compareTwoCommitsMock = compareTwoCommitsMock;
  }

  set successMergeData(String? successMergeMock) {
    this.successMergeMock = successMergeMock;
  }

  set createCommentData(String? createCommentMock) {
    this.createCommentMock = createCommentMock;
  }

  set pullRequestMergeData(String? pullRequestMergeMock) {
    this.pullRequestMergeMock = pullRequestMergeMock;
  }

  set pullrequestFilesData(String? pullRequestFilesMock) {
    pullRequestFilesJsonMock = pullRequestFilesMock;
  }

  set githubIssue(Issue? issue) {
    githubIssueMock = issue;
  }

  @override
  Future<List<CheckRun>> getCheckRuns(
    RepositorySlug slug,
    String ref,
  ) async {
    final rawBody = json.decode(checkRunsMock!) as Map<String, dynamic>;
    final List<dynamic> checkRunsBody = rawBody["check_runs"]! as List<dynamic>;
    List<CheckRun> checkRuns = <CheckRun>[];
    if ((checkRunsBody[0] as Map<String, dynamic>).isNotEmpty) {
      checkRuns.addAll(
        checkRunsBody.map((dynamic checkRun) => CheckRun.fromJson(checkRun as Map<String, dynamic>)).toList(),
      );
    }
    return checkRuns;
  }

  @override
  Future<RepositoryCommit> getCommit(RepositorySlug slug, String sha) async {
    final RepositoryCommit commit = RepositoryCommit.fromJson(jsonDecode(commitMock!) as Map<String, dynamic>);
    return commit;
  }

  @override
  Future<PullRequest> getPullRequest(RepositorySlug slug, int pullRequestNumber) async {
    PullRequest pullRequest;
    if (usePullRequestList && pullRequestMockList.isNotEmpty) {
      pullRequest = pullRequestMockList.removeAt(0)!;
    } else if (usePullRequestList && pullRequestMockList.isEmpty) {
      throw Exception('List is empty.');
    } else {
      pullRequest = pullRequestMock!;
    }
    return pullRequest;
  }

  @override
  Future<GitHubComparison> compareTwoCommits(RepositorySlug slug, String refBase, String refHead) async {
    final GitHubComparison githubComparison =
        GitHubComparison.fromJson(jsonDecode(compareTwoCommitsMock!) as Map<String, dynamic>);
    return githubComparison;
  }

  @override
  Future<bool> removeLabel(RepositorySlug slug, int issueNumber, String label) async {
    labelRemoved = true;
    return labelRemoved;
  }

  @override
  Future<IssueComment> createComment(RepositorySlug slug, int number, String commentBody) async {
    if (useRealComment) {
      issueComment = IssueComment(id: number, body: commentBody);
    } else {
      issueComment = IssueComment.fromJson(jsonDecode(createCommentMock!) as Map<String, dynamic>);
    }
    return issueComment!;
  }

  @override
  Future<bool> updateBranch(RepositorySlug slug, int number, String headSha) async {
    return true;
  }

  @override
  Future<Response> autoMergeBranch(PullRequest pullRequest) {
    // TODO: implement autoMergeBranch
    throw UnimplementedError();
  }

  @override
  Future<List<PullRequestFile>> getPullRequestFiles(RepositorySlug slug, PullRequest pullRequest) async {
    String pullRequestData;

    if (usePullRequestFilesList && pullRequestFilesMockList.isNotEmpty) {
      pullRequestData = pullRequestFilesMockList.removeAt(0)!;
    } else if (usePullRequestFilesList && pullRequestFilesMockList.isEmpty) {
      throw Exception('File list is empty.');
    } else {
      pullRequestData = pullRequestFilesJsonMock as String;
    }

    List<PullRequestFile> pullRequestFileList = [];

    dynamic parsedList = jsonDecode(pullRequestData);

    for (dynamic d in parsedList) {
      PullRequestFile file = PullRequestFile.fromJson(d as Map<String, dynamic>);
      pullRequestFileList.add(file);
    }

    return pullRequestFileList;
  }

  @override
  Future<Issue> createIssue({
    required RepositorySlug slug,
    required String title,
    required String body,
    List<String>? labels,
    String? assignee,
    List<String>? assignees,
    String? state,
  }) async {
    if (throwOnCreateIssue) {
      throw GitHubError(github, 'Exception on github create issue.');
    }
    return githubIssueMock!;
  }

  @override
  Future<bool> comparePullRequests(RepositorySlug repositorySlug, PullRequest revert, PullRequest current) async {
    if (skipRealCompare) {
      return compareReturnValue;
    }

    List<PullRequestFile> revertPullRequestFiles = await getPullRequestFiles(repositorySlug, revert);
    List<PullRequestFile> currentPullRequestFiles = await getPullRequestFiles(repositorySlug, current);

    return _validateFileSetsAreEqual(revertPullRequestFiles, currentPullRequestFiles);
  }

  bool _validateFileSetsAreEqual(
    List<PullRequestFile> revertPullRequestFiles,
    List<PullRequestFile> currentPullRequestFiles,
  ) {
    List<String?> revertFileNames = [];
    List<String?> currentFileNames = [];

    for (var element in revertPullRequestFiles) {
      revertFileNames.add(element.filename);
    }
    for (var element in currentPullRequestFiles) {
      currentFileNames.add(element.filename);
    }

    return revertFileNames.toSet().containsAll(currentFileNames) &&
        currentFileNames.toSet().containsAll(revertFileNames);
  }

  @override
  Future<Issue> getIssue({required RepositorySlug slug, required int issueNumber}) async {
    return githubIssueMock!;
  }
}

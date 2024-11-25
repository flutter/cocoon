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
  String? githubFileContents;

  bool useMergeRequestMockList = false;
  bool trackMergeRequestCalls = false;
  PullRequestMerge? mergeRequestMock;
  List<PullRequestMerge> pullRequestMergeMockList = [];

  /// map to track pull request calls using pull number and repository slug.
  Map<int, RepositorySlug> verifyPullRequestMergeCallMap = {};

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
    final List<dynamic> checkRunsBody = rawBody['check_runs']! as List<dynamic>;
    final List<CheckRun> checkRuns = <CheckRun>[];
    if ((checkRunsBody[0] as Map<String, dynamic>).isNotEmpty) {
      checkRuns.addAll(
        checkRunsBody.map((dynamic checkRun) => CheckRun.fromJson(checkRun as Map<String, dynamic>)).toList(),
      );
    }
    return checkRuns;
  }

  @override
  Future<List<CheckRun>> getCheckRunsFiltered({
    required RepositorySlug slug,
    required String ref,
    String? checkName,
    CheckRunStatus? status,
    CheckRunFilter? filter,
  }) async {
    final List<CheckRun> checkRuns = await getCheckRuns(slug, ref);
    if (checkName != null) {
      final List<CheckRun> checkRunsFilteredByName = [];
      for (CheckRun checkRun in checkRuns) {
        if (checkRun.name == checkName) {
          checkRunsFilteredByName.add(checkRun);
        }
      }
      return checkRunsFilteredByName;
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
  Future<List<IssueLabel>> addLabels(RepositorySlug slug, int issueNumber, List<String> labels) async {
    final List<IssueLabel> labelsAdded = [];
    for (String labelName in labels) {
      labelsAdded.add(IssueLabel(name: labelName));
    }
    return labelsAdded;
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

    final List<PullRequestFile> pullRequestFileList = [];

    final dynamic parsedList = jsonDecode(pullRequestData);

    for (dynamic d in parsedList) {
      final PullRequestFile file = PullRequestFile.fromJson(d as Map<String, dynamic>);
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
  Future<Issue> getIssue({required RepositorySlug slug, required int issueNumber}) async {
    return githubIssueMock!;
  }

  bool throwExceptionOnMerge = false;

  /// If useMergeRequestMockList is true then we will return elements from that
  /// list until it is empty.
  ///
  /// The developer should track the number of times this method is called as
  /// managing an empty list is not done here.
  @override
  Future<PullRequestMerge> mergePullRequest(
    RepositorySlug slug,
    int number, {
    String? commitMessage,
    MergeMethod? mergeMethod,
    String? requestSha,
  }) async {
    if (throwExceptionOnMerge) {
      throw Exception('Exception occurred during merging of pull request.');
    }
    verifyPullRequestMergeCallMap[number] = slug;
    if (useMergeRequestMockList) {
      return pullRequestMergeMockList.removeAt(0);
    } else {
      return mergeRequestMock!;
    }
  }

  void verifyMergePullRequests(Map<int, RepositorySlug> expected) {
    assert(verifyPullRequestMergeCallMap.length == expected.length);
    verifyPullRequestMergeCallMap.forEach((key, value) {
      assert(expected.containsKey(key));
      assert(expected[key] == value);
    });
  }

  bool throwExceptionFileContents = false;

  List<String> fileContentsMockList = [];

  @override
  Future<String> getFileContents(RepositorySlug slug, String path, {String? ref}) async {
    if (throwExceptionFileContents) {
      throw 'Contents do not point to a file.';
    }

    // Assume that the list is not empty.
    return fileContentsMockList.removeAt(0);
  }

  TeamMembershipState? teamMembershipStateMock = TeamMembershipState('active');

  String defaultBranch = 'main';
  bool throwOnDefaultBranch = false;
  Exception exception = Exception('Generic exception.');

  @override
  Future<String> getDefaultBranch(RepositorySlug slug) async {
    if (throwOnDefaultBranch) {
      throw exception;
    } else {
      return defaultBranch;
    }
  }

  Repository repositoryMock = Repository();

  @override
  Future<Repository> getRepository(RepositorySlug slug) async {
    return repositoryMock;
  }

  Map<String, bool> isTeamMemberMockMap = <String, bool>{};

  @override
  Future<bool> isTeamMember(
    String team,
    String user,
    String org,
  ) async {
    if (!isTeamMemberMockMap.containsKey(user)) {
      return false;
    }
    return isTeamMemberMockMap[user]!;
  }

  @override
  Future<PullRequest> createPullRequest({
    required RepositorySlug slug,
    String? title,
    String? head,
    required String base,
    bool draft = false,
    String? body,
  }) {
    // TODO: implement createPullRequest
    throw UnimplementedError();
  }

  @override
  Future<List<PullRequest>> listPullRequests(
    RepositorySlug slug, {
    int? pages,
    String? base,
    String direction = 'desc',
    String? head,
    String sort = 'created',
    String state = 'open',
  }) {
    // TODO: implement listPullRequests
    throw UnimplementedError();
  }

  String? branchMockData;

  set branchMock(String data) => branchMock = data;

  @override
  Future<Branch> getBranch(
    RepositorySlug slug,
    String branchName,
  ) async {
    return Branch.fromJson(json.decode(branchMockData!));
  }

  bool addReviewersToPullRequestMock = true;

  @override
  Future<bool> addReviewersToPullRequest(
    RepositorySlug slug,
    int pullRequestNumber,
    List<String> reviewerLogins,
  ) async {
    return addReviewersToPullRequestMock;
  }

  bool addAssigneeMock = true;

  @override
  Future<bool> addAssignee(
    RepositorySlug slug,
    int number,
    List<String> assignees,
  ) async {
    return addAssigneeMock;
  }

  final List<(RepositorySlug, String)> deletedBranches = [];
  bool deleteBranchMock = true;

  @override
  Future<bool> deleteBranch(
    RepositorySlug slug,
    String branchName,
  ) async {
    deletedBranches.add((slug, branchName));
    return deleteBranchMock;
  }

  List<IssueComment> issueCommentsMock = [];

  @override
  Future<List<IssueComment>> getIssueComments(
    RepositorySlug slug,
    int issueNumber,
  ) async {
    return issueCommentsMock;
  }

  List<PullRequestReview> pullRequestReviewsMock = [];

  @override
  Future<List<PullRequestReview>> getPullRequestReviews(
    RepositorySlug slug,
    int pullRequestNumber,
  ) async {
    return pullRequestReviewsMock;
  }
}

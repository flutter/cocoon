// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:github/github.dart';
import 'package:googleapis/bigquery/v2.dart';
import 'package:meta/meta.dart';
import 'package:yaml/yaml.dart';

import '../request_handling/api_request_handler.dart';
import '../request_handling/authentication.dart';
import '../request_handling/body.dart';
import '../service/config.dart';

import 'check_flaky_tests_and_update_github_utils.dart';

@immutable
class CheckForFlakyTestAndUpdateGithub extends ApiRequestHandler<Body> {
  const CheckForFlakyTestAndUpdateGithub(
    Config config,
    AuthenticationProvider authenticationProvider) : super(config: config, authenticationProvider: authenticationProvider);

  static const String _thresholdKey = 'threshold';
  static const String _ciYamlPath = '.ci.yaml';
  static const String _ciYamlTargetsKey = 'targets';
  static const String _ciYamlTargetBuilderKey = 'builder';
  static const String _ciYamlTargetNameKey = 'name';
  static const String _ciYamlTargetIsFlakyKey = 'bringup';
  static const String _testOwnerPath = 'TESTOWNERS';
  static const String _masterRefs = 'heads/master';
  static const String _refsPrefix = 'refs/heads/';
  static const String _modifyMode = '100755';
  static const String _modifyType = 'blob';

  static const int _kGracePeriodForClosedFlake = 15; // days

  @override
  Future<Body> get() async {
    try {
      final GitHub client = await config.createGitHubClientWithToken(await config.githubFlakyBotOAuthToken);
      final Map<String, BuilderStats> nameToStats = await _getBuilderStats(client);
      final Map<String, ExistingGithubIssue> nameToExistingIssue = await _getExistingGithubIssues(client);
      final Map<String, ExistingGithubPR> nameToExistingPR = await _getExistingGithubPRs(client);
      final Set<String> importantFlakes = _getImportantFlakes(nameToStats.values.toList(), _threshold);
      // Makes sure every the important flake has an github issue and a pr to
      // make the test flaky.
      for (String builderName in importantFlakes) {
        await _updateFlakes(
          client: client,
          newStats: nameToStats[builderName],
          existingIssues: nameToExistingIssue,
          existingPRs: nameToExistingPR,
          isImportant: true
        );
      }
      // For existing issues that are not important flakes, update them with the
      // newest metrics or close them if they are no longer flaky.
      for (final String name in nameToExistingIssue.keys) {
        if (nameToExistingIssue[name].issue.isOpen) {
          if (!nameToStats.containsKey(name) || nameToStats[name].flakyRate == 0.0) {
            await _maybeCloseIssue(nameToExistingIssue[name].issue, client);
          } else {
            await _updateFlakes(
              client: client,
              newStats: nameToStats[name],
              existingIssues: nameToExistingIssue,
              existingPRs: nameToExistingPR,
              isImportant: false,
            );
          }
        }
      }
    } catch (e, stack) {
      return Body.forJson(<String, dynamic>{
        'Statuses': e.toString(),
        'stack': stack.toString(),
      });
    }
    return Body.forJson(const <String, dynamic>{
      'Statuses': 'success',
    });
  }

  double get _threshold => double.parse(request.uri.queryParameters[_thresholdKey]);

  String _generateNewRef() {
    const String chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    final Random rnd = Random();
    final String randomString = String.fromCharCodes(Iterable<int>.generate(
        10, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
    return '${_refsPrefix}marks-flaky-$randomString';
  }

  Future<Map<String, BuilderStats>> _getBuilderStats(GitHub client) async {
    const String projectId = 'flutter-dashboard';

    final JobsResourceApi jobsResourceApi = await config.createJobsResourceApi();
    final QueryRequest query = QueryRequest.fromJson(<String, Object>{
      'query': getFlakyRateQuery,
      'useLegacySql': false
    });
    final QueryResponse response = await jobsResourceApi.query(query, projectId);
    if (!response.jobComplete) {
      throw 'job does not complete';
    }
    final Map<String, BuilderStats> nameToStats = <String, BuilderStats>{};
    final String testOwnerContent = await _getTestOwnerContent(client);
    final YamlMap ci = loadYaml(await _getCIContent(client)) as YamlMap;
    final YamlList targets = ci[_ciYamlTargetsKey] as YamlList;
    for (final TableRow row in response.rows) {
      final String builder = row.f[0].v as String;
      List<String> failedBuilds = (row.f[3].v as String)?.split(', ');
      failedBuilds?.sort();
      failedBuilds = failedBuilds?.reversed?.toList();
      List<String> succeededBuilds = (row.f[4].v as String)?.split(', ');
      succeededBuilds?.sort();
      succeededBuilds = succeededBuilds?.reversed?.toList();
      final YamlMap target = targets.firstWhere(
        (dynamic element) => element[_ciYamlTargetBuilderKey] == builder,
        orElse: () => null,
      ) as YamlMap;
      if (target == null) {
        continue;
      }
      final String testName = target[_ciYamlTargetNameKey] as String;
      nameToStats[builder] = BuilderStats(
        name: builder,
        flakyRate: double.parse(row.f[7].v as String),
        failedBuilds: failedBuilds ?? const <String>[],
        succeededBuilds: succeededBuilds ?? const <String>[],
        recentCommit: row.f[5].v as String,
        failedBuildOfRecentCommit: row.f[6].v as String,
        testOwner: await _findTestOwner(testName, testOwnerContent)
      );
    }
    return nameToStats;
  }

  Future<Map<String, ExistingGithubIssue>> _getExistingGithubIssues(GitHub client) async {
    final Map<String, ExistingGithubIssue> nameToExistingIssue = <String, ExistingGithubIssue>{};
    await for (final Issue issue in client.issues.listByRepo(
        config.flutterSlug, state:'all', labels: <String>[kFlakeLabel])) {
      final RegExpMatch match = IssueBuilder.issueTitleRegex.firstMatch(issue.title);
      if (match != null) {
        if (!nameToExistingIssue.containsKey(match.namedGroup('name')) ||
            _isOtherIssueMoreImportant(nameToExistingIssue[match.namedGroup('name')].issue, issue)) {
          nameToExistingIssue[match.namedGroup('name')] = ExistingGithubIssue(
            match.namedGroup('name'),
            issue,
          );
        }
      }
    }
    return nameToExistingIssue;
  }

  Future<Map<String, ExistingGithubPR>> _getExistingGithubPRs(GitHub client) async {
    final Map<String, ExistingGithubPR> nameToExistingPRs = <String, ExistingGithubPR>{};
    await for (final PullRequest pr in client.pullRequests.list(config.flutterSlug)) {
      final RegExpMatch match = pullRequestTitleRegex.firstMatch(pr.title);
      if (match != null) {
        nameToExistingPRs[match.namedGroup('name')] = ExistingGithubPR(
          match.namedGroup('name'),
          pr
        );
      }
    }
    return nameToExistingPRs;
  }

  Set<String> _getImportantFlakes(List<BuilderStats> statsList, double threshold) {
    final Set<String> importantFlakes = <String>{};
    for (final BuilderStats stats in statsList) {
      if (stats.flakyRate > threshold) {
        importantFlakes.add(stats.name);
      }
    }
    if (importantFlakes.isNotEmpty) {
      return importantFlakes;
    }
    BuilderStats mostImportant;
    for (final BuilderStats stats in statsList) {
      if (mostImportant == null || mostImportant.flakyRate < stats.flakyRate) {
        mostImportant = stats;
      }
    }
    return <String>{
      if (mostImportant != null)
        mostImportant.name,
    };
  }

  Future<void> _updateFlakes({
    GitHub client,
    BuilderStats newStats,
    Map<String, ExistingGithubIssue> existingIssues,
    Map<String, ExistingGithubPR> existingPRs,
    bool isImportant = false,
  }) async {
    // Don't create a new issue if there is a recent closed issue within
    // _kGracePeriodForClosedFlake days. It takes time for the flaky ratio to go
    // down after the fixed is merged.
    Issue issue;
    if (!existingIssues.containsKey(newStats.name) ||
        (existingIssues[newStats.name].issue.state == 'closed' &&
         existingIssues[newStats.name].issue.closedAt.difference(DateTime.now())> const Duration(days: _kGracePeriodForClosedFlake))) {
      if (!isImportant) {
        throw 'This handler should only create new issue for important flake, something went wrong!';
      }
      issue = await _fileNewIssue(
        stats: newStats,
        client: client,
      );
    } else if(existingIssues.containsKey(newStats.name) && existingIssues[newStats.name].issue.state == 'open') {
      issue = await _updateIssue(
        stats: newStats,
        existingIssue: existingIssues[newStats.name],
        client: client,
        isImportant: isImportant
      );
    } else {
      // Do nothing if there is a closed issue within _kGracePeriodForClosedFlake days.
      return;
    }
    if (isImportant) {
      if (issue == null) {
        throw 'This issue not be null for important flake, something went wrong!';
      }
      await _fileNewPullRequestIfNeeded(
          stats:newStats,
          issue: issue,
          existingPRs: existingPRs,
          client: client,
      );
    }
  }

  Future<void> _maybeCloseIssue(Issue issue, GitHub client) async {
    if (issue.assignee != null) {
      return;
    }
    await client.issues.createComment(config.flutterSlug, issue.number, kCloseIssueComment);
    await client.issues.edit(
      config.flutterSlug,
      issue.number,
      IssueRequest(
        state: 'closed',
      ),
    );
  }

  Future<Issue> _fileNewIssue({BuilderStats stats, GitHub client}) async {
    // The script should only create issue if the flake is important.
    final IssueBuilder issueBuilder = IssueBuilder(stats: stats, threshold: _threshold, isImportant: true);
    return await client.issues.create(
      config.flutterSlug,
      IssueRequest(
        title: issueBuilder.issueTitle,
        body: issueBuilder.issueBody,
        labels: issueBuilder.issueLabels,
        assignee: stats.testOwner,
      ),
    );
  }

  Future<Issue> _updateIssue({
    BuilderStats stats,
    ExistingGithubIssue existingIssue,
    GitHub client,
    bool isImportant
  }) async {
    final IssueBuilder issueBuilder = IssueBuilder(stats: stats, threshold: _threshold, isImportant: isImportant);
    return await client.issues.edit(
      config.flutterSlug,
      existingIssue.issue.number,
      IssueRequest(
        title: issueBuilder.issueTitle,
        body: issueBuilder.updateIssueBody(existingIssue.issue.body),
        labels: issueBuilder.updateIssueLabels(existingIssue.issue.labels),
        state: 'open',
        milestone: existingIssue.issue.milestone?.number,
      ),
    );
  }

  Future<void> _fileNewPullRequestIfNeeded({
    BuilderStats stats,
    Issue issue,
    Map<String, ExistingGithubPR> existingPRs,
    GitHub client,
  }) async {
    if (existingPRs.containsKey(stats.name)) {
      return;
    }
    // Check whether the test has already been marked as flaky.
    final String contentRaw = await _getCIContent(client);
    final YamlMap content = loadYaml(contentRaw) as YamlMap;
    final YamlList targets = content[_ciYamlTargetsKey] as YamlList;
    final YamlMap target = targets.firstWhere(
      (dynamic element) => element[_ciYamlTargetBuilderKey] == stats.name,
    ) as YamlMap;
    if (target[_ciYamlTargetIsFlakyKey] == true) {
      // Already marked as flaky.
      return;
    }
    // await client.repositories.deleteRepository(config.flutterflakybotSlug);
    // await client.repositories.createFork(RepositorySlug('flutter', 'flutter'));
    final String modifiedContent = _marksBuildFlakyInContent(contentRaw, stats.name);
    final String ref = _generateNewRef();
    final GitReference masterRef = await client.git.getReference(config.flutterSlug, _masterRefs);
    final GitTree tree = await client.git.createTree(
      config.flutterflakybotSlug,
      CreateGitTree(
        <CreateGitTreeEntry>[
          CreateGitTreeEntry(
            _ciYamlPath,
            _modifyMode,
            _modifyType,
            content: modifiedContent,
          )
        ],
        baseTree: masterRef.object.sha,
      )
    );
    final CurrentUser currentUser = await client.users.getCurrentUser();
    final GitCommitUser commitUser = GitCommitUser(currentUser.name, currentUser.email, DateTime.now());
    final PullRequestBuilder prBuilder = PullRequestBuilder(stats: stats, issue: issue);
    final GitCommit commit = await client.git.createCommit(
      config.flutterflakybotSlug,
      CreateGitCommit(
        prBuilder.pullRequestTitle,
        tree.sha,
        parents: <String>[masterRef.object.sha],
        author: commitUser,
        committer: commitUser,
      ),
    );
    final GitReference changeRef = await client.git.createReference(config.flutterflakybotSlug, ref, commit.sha);
    final PullRequest pr = await client.pullRequests.create(
      config.flutterSlug,
      CreatePullRequest(
        prBuilder.pullRequestTitle,
        '${config.flutterflakybotSlug.owner}:${ref.replaceFirst(_refsPrefix, '')}',
        'master',
        body: prBuilder.pullRequestBody,
      ),
    );
    await _assignReviewerFor(pr, reviewer: stats.testOwner, client: client);
  }

  Future<void> _assignReviewerFor(PullRequest pr, {String reviewer, GitHub client}) async {
    const JsonEncoder encoder = JsonEncoder();
    await client.postJSON<Map<String, dynamic>, PullRequest>(
      '/repos/${config.flutterSlug.fullName}/pulls/${pr.number}/requested_reviewers',
      convert: (Map<String, dynamic> i) => PullRequest.fromJson(i),
      body: encoder.convert(<String, dynamic>{
        'reviewers': <String>[reviewer],
      }),
    );
  }

  bool _isOtherIssueMoreImportant(Issue original, Issue other) {
    // Open issues are always more important than closed issues. If both issue
    // are closed, the one that is most recent created is more important.
    if (original.isOpen && other.isOpen) {
      throw 'There should not be two open issues for the same test';
    } else if (original.isOpen && other.isClosed) {
      return false;
    } else if (original.isClosed && other.isOpen) {
      return true;
    } else {
      return other.createdAt.isAfter(original.createdAt);
    }
  }

  Future<String> _getCIContent(GitHub client) async {
    final RepositoryContents contents = await client.repositories.getContents(config.flutterSlug, _ciYamlPath);
    if (!contents.isFile) {
      throw 'The path $_ciYamlPath should point to a file, but it is not!';
    }
    final String content = utf8.decode(base64.decode(contents.file.content.replaceAll('\n', '')));
    return content;
  }

  Future<String> _getTestOwnerContent(GitHub client) async {
    final RepositoryContents contents = await client.repositories.getContents(config.flutterSlug, _testOwnerPath);
    if (!contents.isFile) {
      throw 'The path $_ciYamlPath should point to a file, but it is not!';
    }
    final String content = utf8.decode(base64.decode(contents.file.content.replaceAll('\n', '')));
    return content;
  }

  Future<String> _findTestOwner(String testName, String testOwnersContent) async {
    final List<String> lines = testOwnersContent.split('\n');
    String owner;
    for (final String line in lines) {
      if (line.startsWith('#')) {
        continue;
      }
      if (line.trim().isEmpty) {
        continue;
      }
      final List<String> words = line.trim().split(' ');
      if (words[0].contains(testName)) {
        owner = words[1].substring(1); // Strip out the lead '@'
      }
    }
    return owner;
  }

  String _marksBuildFlakyInContent(String content, String builder) {
    final List<String> lines = content.split('\n');
    final int builderLineNumber = lines.indexWhere((String line) => line.contains('builder: $builder'));
    // Takes care the case if is _ciYamlTargetIsFlakyKey is already defined to false
    int nextLine = builderLineNumber + 1;
    while(!lines[nextLine].contains('builder:')) {
      if (lines[nextLine].contains('$_ciYamlTargetIsFlakyKey:')) {
        lines[nextLine] = lines[nextLine].replaceFirst('false', 'true');
        return lines.join('\n');
      }
      nextLine += 1;
    }
    lines.insert(nextLine + 1, '    $_ciYamlTargetIsFlakyKey: true');
    return lines.join('\n');
  }
}

class ExistingGithubIssue {
  ExistingGithubIssue(
    this.name,
    this.issue,
  );
  final String name;
  final Issue issue;
}

class ExistingGithubPR {
  ExistingGithubPR(
    this.name,
    this.pr,
  );
  final String name;
  final PullRequest pr;
}


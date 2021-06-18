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
  const CheckForFlakyTestAndUpdateGithub(Config config, AuthenticationProvider authenticationProvider)
      : super(config: config, authenticationProvider: authenticationProvider);

  static const String kBigQueryProjectId = 'flutter-dashboard';

  static const String kThresholdKey = 'threshold';
  static const String kCiYamlPath = '.ci.yaml';
  static const String _ciYamlTargetsKey = 'targets';
  static const String _ciYamlTargetBuilderKey = 'builder';
  static const String _ciYamlTargetIsFlakyKey = 'bringup';
  static const String kTestOwnerPath = 'TESTOWNERS';
  static const String kMasterRefs = 'heads/master';
  static const String kRefsPrefix = 'refs/heads/';
  static const String kModifyMode = '100755';
  static const String kModifyType = 'blob';

  static const int kGracePeriodForClosedFlake = 15; // days

  @override
  Future<Body> get() async {
    try {
      final RepositorySlug slug = config.flutterSlug;
      final GitHub client = await config.createGitHubClientWithToken(await config.githubFlakyBotOAuthToken);
      final Map<String, BuilderStats> nameToStats = await _getBuilderStats(client, slug);
      final Map<String, _ExistingIssue> nameToExistingIssue = await _getExistingIssues(client, slug);
      final Map<String, _ExistingPR> nameToExistingPR = await _getExistingPRs(client, slug);
      // Finds the important flakes whose flaky rate > threshold or the most flaky test
      // if all of the flakes < threshold.
      final Set<String> importantFlakes = _getImportantFlakes(nameToStats.values.toList(), _threshold);
      // Makes sure every important flake has an github issue and a pr to mark
      // the test flaky.
      for (String builderName in importantFlakes) {
        await _updateFlakes(
          client: client,
          newStats: nameToStats[builderName],
          existingIssues: nameToExistingIssue,
          existingPRs: nameToExistingPR,
          slug: slug,
        );
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

  double get _threshold => double.parse(request.uri.queryParameters[kThresholdKey]);

  String _generateNewRef() {
    const String chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    final Random rnd = Random();
    final String randomString =
        String.fromCharCodes(Iterable<int>.generate(10, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
    return '${kRefsPrefix}marks-flaky-$randomString';
  }

  Future<Map<String, BuilderStats>> _getBuilderStats(GitHub client, RepositorySlug slug) async {
    final JobsResourceApi jobsResourceApi = await config.createJobsResourceApi();
    final QueryRequest query =
        QueryRequest.fromJson(<String, Object>{'query': getFlakyRateQuery, 'useLegacySql': false});
    final QueryResponse response = await jobsResourceApi.query(query, kBigQueryProjectId);
    if (!response.jobComplete) {
      throw 'job does not complete';
    }
    final Map<String, BuilderStats> nameToStats = <String, BuilderStats>{};
    final String testOwnerContent = await _getTestOwnerContent(client, slug);
    final YamlMap ci = loadYaml(await _getCIContent(client, slug)) as YamlMap;
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
      final String testName = _getTestNameFromBuilderName(builder);
      nameToStats[builder] = BuilderStats(
          name: builder,
          flakyRate: double.parse(row.f[7].v as String),
          failedBuilds: failedBuilds ?? const <String>[],
          succeededBuilds: succeededBuilds ?? const <String>[],
          recentCommit: row.f[5].v as String,
          failedBuildOfRecentCommit: row.f[6].v as String,
          testOwner: await _findTestOwner(testName, testOwnerContent));
    }
    return nameToStats;
  }

  Future<Map<String, _ExistingIssue>> _getExistingIssues(GitHub client, RepositorySlug slug) async {
    final Map<String, _ExistingIssue> nameToExistingIssue = <String, _ExistingIssue>{};
    await for (final Issue issue in client.issues.listByRepo(slug, state: 'all', labels: <String>[kTeamFlakeLabel])) {
      final RegExpMatch match = IssueBuilder.issueTitleRegex.firstMatch(issue.title);
      if (match != null) {
        if (!nameToExistingIssue.containsKey(match.namedGroup('name')) ||
            _isOtherIssueMoreImportant(nameToExistingIssue[match.namedGroup('name')].issue, issue)) {
          nameToExistingIssue[match.namedGroup('name')] = _ExistingIssue(
            match.namedGroup('name'),
            issue,
          );
        }
      }
    }
    return nameToExistingIssue;
  }

  Future<Map<String, _ExistingPR>> _getExistingPRs(GitHub client, RepositorySlug slug) async {
    final Map<String, _ExistingPR> nameToExistingPRs = <String, _ExistingPR>{};
    await for (final PullRequest pr in client.pullRequests.list(slug)) {
      final RegExpMatch match = pullRequestTitleRegex.firstMatch(pr.title);
      if (match != null) {
        nameToExistingPRs[match.namedGroup('name')] = _ExistingPR(match.namedGroup('name'), pr);
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
    // No flake is above threshold.
    BuilderStats mostImportant;
    for (final BuilderStats stats in statsList) {
      if (mostImportant == null || mostImportant.flakyRate < stats.flakyRate) {
        mostImportant = stats;
      }
    }
    return <String>{
      if (mostImportant != null) mostImportant.name,
    };
  }

  Future<void> _updateFlakes({
    @required GitHub client,
    @required RepositorySlug slug,
    @required BuilderStats newStats,
    @required Map<String, _ExistingIssue> existingIssues,
    @required Map<String, _ExistingPR> existingPRs,
  }) async {
    // Don't create a new issue if there is a recent closed issue within
    // kGracePeriodForClosedFlake days. It takes time for the flaky ratio to go
    // down after the fix is merged.
    Issue issue = existingIssues[newStats.name]?.issue;
    if (!existingIssues.containsKey(newStats.name) ||
        (existingIssues[newStats.name].issue.state == 'closed' &&
            DateTime.now().difference(existingIssues[newStats.name].issue.closedAt) >
                const Duration(days: kGracePeriodForClosedFlake))) {
      issue = await _fileNewIssue(
        stats: newStats,
        client: client,
        slug: slug,
      );
    }
    if (issue != null) {
      await _fileNewPullRequestIfNeeded(
        stats: newStats,
        issue: issue,
        existingPRs: existingPRs,
        client: client,
        slug: slug,
      );
    }
  }

  Future<Issue> _fileNewIssue(
      {@required BuilderStats stats, @required GitHub client, @required RepositorySlug slug}) async {
    // The script should only create issue if the flake is important.
    final IssueBuilder issueBuilder = IssueBuilder(stats: stats, threshold: _threshold, isImportant: true);
    return await client.issues.create(
      slug,
      IssueRequest(
        title: issueBuilder.issueTitle,
        body: issueBuilder.issueBody,
        labels: issueBuilder.issueLabels,
        assignee: stats.testOwner,
      ),
    );
  }

  Future<void> _fileNewPullRequestIfNeeded({
    @required BuilderStats stats,
    @required Issue issue,
    @required Map<String, _ExistingPR> existingPRs,
    @required GitHub client,
    @required RepositorySlug slug,
  }) async {
    if (existingPRs.containsKey(stats.name)) {
      return;
    }
    // Check whether the test has already been marked as flaky.
    final String contentRaw = await _getCIContent(client, slug);
    final YamlMap content = loadYaml(contentRaw) as YamlMap;
    final YamlList targets = content[_ciYamlTargetsKey] as YamlList;
    final YamlMap target = targets.firstWhere(
      (dynamic element) => element[_ciYamlTargetBuilderKey] == stats.name,
    ) as YamlMap;
    if (target[_ciYamlTargetIsFlakyKey] == true) {
      // Already marked as flaky.
      return;
    }
    final String modifiedContent = _marksBuildFlakyInContent(contentRaw, stats.name, issue.htmlUrl);
    final String ref = _generateNewRef();
    final GitReference masterRef = await client.git.getReference(slug, kMasterRefs);
    final RepositorySlug clientSlug = await getSlugFor(client, slug.name);
    final GitTree tree = await client.git.createTree(
        clientSlug,
        CreateGitTree(
          <CreateGitTreeEntry>[
            CreateGitTreeEntry(
              kCiYamlPath,
              kModifyMode,
              kModifyType,
              content: modifiedContent,
            )
          ],
          baseTree: masterRef.object.sha,
        ));
    final CurrentUser currentUser = await client.users.getCurrentUser();
    final GitCommitUser commitUser = GitCommitUser(currentUser.name, currentUser.email, DateTime.now());
    final PullRequestBuilder prBuilder = PullRequestBuilder(stats: stats, issue: issue);
    final GitCommit commit = await client.git.createCommit(
      clientSlug,
      CreateGitCommit(
        prBuilder.pullRequestTitle,
        tree.sha,
        parents: <String>[masterRef.object.sha],
        author: commitUser,
        committer: commitUser,
      ),
    );
    await client.git.createReference(clientSlug, ref, commit.sha);
    final PullRequest pr = await client.pullRequests.create(
      slug,
      CreatePullRequest(
        prBuilder.pullRequestTitle,
        '${clientSlug.owner}:${ref.replaceFirst(kRefsPrefix, '')}',
        'master',
        body: prBuilder.pullRequestBody,
      ),
    );
    await _assignReviewerFor(pr, reviewer: stats.testOwner, client: client, slug: slug);
  }

  Future<void> _assignReviewerFor(
    PullRequest pr, {
    @required String reviewer,
    @required GitHub client,
    @required RepositorySlug slug,
  }) async {
    const JsonEncoder encoder = JsonEncoder();
    await client.postJSON<Map<String, dynamic>, PullRequest>(
      '/repos/${slug.fullName}/pulls/${pr.number}/requested_reviewers',
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

  Future<String> _getCIContent(GitHub client, RepositorySlug slug) async {
    final RepositoryContents contents = await client.repositories.getContents(slug, kCiYamlPath);
    if (!contents.isFile) {
      throw 'The path $kCiYamlPath should point to a file, but it is not!';
    }
    final String content = utf8.decode(base64.decode(contents.file.content.replaceAll('\n', '')));
    return content;
  }

  Future<String> _getTestOwnerContent(GitHub client, RepositorySlug slug) async {
    final RepositoryContents contents = await client.repositories.getContents(slug, kTestOwnerPath);
    if (!contents.isFile) {
      throw 'The path $kTestOwnerPath should point to a file, but it is not!';
    }
    final String content = utf8.decode(base64.decode(contents.file.content.replaceAll('\n', '')));
    return content;
  }

  String _getTestNameFromBuilderName(String builderName) {
    // The builder names is in the format '<platform> <test name>'.
    final List<String> words = builderName.split(' ');
    return words.length < 2 ? words[0] : words[1];
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

  String _marksBuildFlakyInContent(String content, String builder, String issueUrl) {
    final List<String> lines = content.split('\n');
    final int builderLineNumber = lines.indexWhere((String line) => line.contains('builder: $builder'));
    // Takes care the case if is _ciYamlTargetIsFlakyKey is already defined to false
    int nextLine = builderLineNumber + 1;
    while (nextLine < lines.length && !lines[nextLine].contains('builder:')) {
      if (lines[nextLine].contains('$_ciYamlTargetIsFlakyKey:')) {
        lines[nextLine] = lines[nextLine].replaceFirst('false', 'true // Flaky $issueUrl');
        return lines.join('\n');
      }
      nextLine += 1;
    }
    lines.insert(builderLineNumber + 1, '    $_ciYamlTargetIsFlakyKey: true // Flaky $issueUrl');
    return lines.join('\n');
  }

  Future<RepositorySlug> getSlugFor(GitHub client, String repository) async {
    return RepositorySlug((await client.users.getCurrentUser()).login, repository);
  }
}

class _ExistingIssue {
  _ExistingIssue(
    this.name,
    this.issue,
  );
  final String name;
  final Issue issue;
}

class _ExistingPR {
  _ExistingPR(
    this.name,
    this.pr,
  );
  final String name;
  final PullRequest pr;
}

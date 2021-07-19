// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:github/github.dart';
import 'package:meta/meta.dart';
import 'package:yaml/yaml.dart';

import '../request_handling/api_request_handler.dart';
import '../request_handling/authentication.dart';
import '../request_handling/body.dart';
import '../service/bigquery.dart';
import '../service/config.dart';
import '../service/github_service.dart';
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
  static const String _ciYamlPropertiesKey = 'properties';
  static const String _ciYamlTargetTagsKey = 'tags';
  static const String _ciYamlTargetTagsShard = 'shard';
  static const String _ciYamlTargetTagsDevicelab = 'devicelab';
  static const String _ciYamlTargetTagsFramework = 'framework';
  static const String _ciYamlTargetTagsHostonly = 'hostonly';

  static const String kTestOwnerPath = 'TESTOWNERS';

  static const String kMasterRefs = 'heads/master';
  static const String kModifyMode = '100755';
  static const String kModifyType = 'blob';

  static const int kGracePeriodForClosedFlake = 15; // days

  @override
  Future<Body> get() async {
    final RepositorySlug slug = config.flutterSlug;
    final GithubService gitHub = config.createGithubServiceWithToken(await config.githubOAuthToken);
    final BigqueryService bigquery = await config.createBigQueryService();
    final List<BuilderStatistic> builderStatisticList = await bigquery.listBuilderStatistic(kBigQueryProjectId);
    final YamlMap ci = loadYaml(await gitHub.getFileContent(slug, kCiYamlPath)) as YamlMap;
    final String testOwnerContent = await gitHub.getFileContent(slug, kTestOwnerPath);
    final List<_BuilderDetail> builderDetails = <_BuilderDetail>[];
    final Map<String, Issue> nameToExistingIssue = await _getExistingIssues(gitHub, slug);
    final Map<String, PullRequest> nameToExistingPR = await _getExistingPRs(gitHub, slug);
    for (final BuilderStatistic statistic in builderStatisticList) {
      final _BuilderType type = _getTypeFromTags(_getTags(statistic.name, ci));
      builderDetails.add(_BuilderDetail(
          statistic: statistic,
          existingIssue: nameToExistingIssue[statistic.name],
          existingPullRequest: nameToExistingPR[statistic.name],
          isMarkedFlaky: _getIsMarkedFlaky(statistic.name, ci),
          type: type,
          owner: _getTestOwner(statistic.name, type, testOwnerContent)));
    }
    // Finds the important flakes whose flaky rate > threshold or the most flaky test
    // if all of the flakes < threshold.
    final Set<String> importantFlakes = _getImportantFlakes(builderStatisticList, _threshold);
    // Makes sure every important flake has an github issue and a pr to mark
    // the test flaky.
    for (final _BuilderDetail detail in builderDetails) {
      await _updateFlakes(
        gitHub,
        slug,
        builderDetail: detail,
        isImportant: importantFlakes.contains(detail.statistic.name)
      );
    }
    return Body.forJson(const <String, dynamic>{
      'Statuses': 'success',
    });
  }

  double get _threshold => double.parse(request.uri.queryParameters[kThresholdKey]);

  Future<Map<String, Issue>> _getExistingIssues(GithubService gitHub, RepositorySlug slug) async {
    final Map<String, Issue> nameToExistingIssue = <String, Issue>{};
    for (final Issue issue in await gitHub.listIssues(slug, state: 'all', labels: <String>[kTeamFlakeLabel])) {
      if (issue.htmlUrl?.contains('pull') == true) {
        // For some reason, this github api may also return pull requests.
        continue;
      }
      final Map<String, dynamic> metaTags = retrieveMetaTagsFromContent(issue.body);
      if (metaTags != null) {
        final String name = metaTags['name'] as String;
        if (!nameToExistingIssue.containsKey(name) || _isOtherIssueMoreImportant(nameToExistingIssue[name], issue)) {
          nameToExistingIssue[name] = issue;
        }
      }
    }
    return nameToExistingIssue;
  }

  Future<Map<String, PullRequest>> _getExistingPRs(GithubService gitHub, RepositorySlug slug) async {
    final Map<String, PullRequest> nameToExistingPRs = <String, PullRequest>{};
    for (final PullRequest pr in await gitHub.listPullRequests(slug, null)) {
      final Map<String, dynamic> metaTags = retrieveMetaTagsFromContent(pr.body);
      if (metaTags != null) {
        nameToExistingPRs[metaTags['name'] as String] = pr;
      }
    }
    return nameToExistingPRs;
  }

  Set<String> _getImportantFlakes(List<BuilderStatistic> statisticList, double threshold) {
    final Set<String> importantFlakes = <String>{};
    for (final BuilderStatistic statistic in statisticList) {
      if (statistic.flakyRate > threshold) {
        importantFlakes.add(statistic.name);
      }
    }
    if (importantFlakes.isNotEmpty) {
      return importantFlakes;
    }
    // No flake is above threshold.
    BuilderStatistic mostImportant;
    for (final BuilderStatistic statistic in statisticList) {
      if (mostImportant == null || mostImportant.flakyRate < statistic.flakyRate) {
        mostImportant = statistic;
      }
    }
    return <String>{
      if (mostImportant != null) mostImportant.name,
    };
  }

  Future<void> _updateFlakes(
    GithubService gitHub,
    RepositorySlug slug, {
    @required _BuilderDetail builderDetail,
    @required bool isImportant,
  }) async {
    // Don't create a new issue if there is a recent closed issue within
    // kGracePeriodForClosedFlake days. It takes time for the flaky ratio to go
    // down after the fix is merged.
    Issue issue = builderDetail.existingIssue;
    if (isImportant &&
        (issue == null ||
         (issue.state == 'closed' &&
             DateTime.now().difference(issue.closedAt) > const Duration(days: kGracePeriodForClosedFlake)))) {
      final IssueBuilder issueBuilder =
          IssueBuilder(statistic: builderDetail.statistic, threshold: _threshold);
      issue = await gitHub.createIssue(
        slug,
        title: issueBuilder.issueTitle,
        body: issueBuilder.issueBody,
        labels: issueBuilder.issueLabels,
        assignee: builderDetail.owner,
      );
    } else if (issue?.isOpen == true) {
      final IssueBuilder issueBuilder =
          IssueBuilder(statistic: builderDetail.statistic, threshold: _threshold, openedIssue: issue);
      await gitHub.createComment(slug, issueNumber: issue.number, body: issueBuilder.issueUpdateComment);
      await gitHub.replaceLabelsForIssue(slug, issueNumber: issue.number, labels: issueBuilder.issueLabels);
    }
    if (!isImportant ||
        issue == null ||
        builderDetail.type == _BuilderType.shard ||
        builderDetail.existingPullRequest != null ||
        builderDetail.isMarkedFlaky) {
      return;
    }
    final String modifiedContent = _marksBuildFlakyInContent(
        await gitHub.getFileContent(slug, kCiYamlPath), builderDetail.statistic.name, issue.htmlUrl);
    final GitReference masterRef = await gitHub.getReference(slug, kMasterRefs);
    final PullRequestBuilder prBuilder = PullRequestBuilder(statistic: builderDetail.statistic, issue: issue);
    final PullRequest pullRequest = await gitHub.createPullRequest(slug,
        title: prBuilder.pullRequestTitle,
        body: prBuilder.pullRequestBody,
        commitMessage: prBuilder.pullRequestTitle,
        baseRef: masterRef,
        entries: <CreateGitTreeEntry>[
          CreateGitTreeEntry(
            kCiYamlPath,
            kModifyMode,
            kModifyType,
            content: modifiedContent,
          )
        ]);
    await gitHub.assignReviewer(slug, reviewer: builderDetail.owner, pullRequestNumber: pullRequest.number);
  }

  bool _getIsMarkedFlaky(String builderName, YamlMap ci) {
    final YamlList targets = ci[_ciYamlTargetsKey] as YamlList;
    final YamlMap target = targets.firstWhere(
      (dynamic element) => element[_ciYamlTargetBuilderKey] == builderName,
      orElse: () => null,
    ) as YamlMap;
    return target != null && target[_ciYamlTargetIsFlakyKey] == true;
  }

  List<dynamic> _getTags(String builderName, YamlMap ci) {
    final YamlList targets = ci[_ciYamlTargetsKey] as YamlList;
    final YamlMap target = targets.firstWhere(
      (dynamic element) => element[_ciYamlTargetBuilderKey] == builderName,
      orElse: () => null,
    ) as YamlMap;
    if (target == null) {
      return null;
    }
    return jsonDecode(target[_ciYamlPropertiesKey][_ciYamlTargetTagsKey] as String) as List<dynamic>;
  }

  _BuilderType _getTypeFromTags(List<dynamic> tags) {
    if (tags == null) {
      return _BuilderType.unknown;
    }
    bool hasFrameworkTag = false;
    bool hasHostOnlyTag = false;
    // If tags contain 'shard', it must be a shard test.
    // If tags contain 'devicelab', it must be a devicelab test.
    // Otherwise, it is framework host only test if its tags contain both
    // 'framework' and 'hostonly'.
    for (dynamic tag in tags) {
      if (tag == _ciYamlTargetTagsShard) {
        return _BuilderType.shard;
      } else if (tag == _ciYamlTargetTagsDevicelab) {
        return _BuilderType.devicelab;
      } else if (tag == _ciYamlTargetTagsFramework) {
        hasFrameworkTag = true;
      } else if (tag == _ciYamlTargetTagsHostonly) {
        hasHostOnlyTag = true;
      }
    }
    return hasFrameworkTag && hasHostOnlyTag ? _BuilderType.frameworkHostOnly : _BuilderType.unknown;
  }

  bool _isOtherIssueMoreImportant(Issue original, Issue other) {
    // Open issues are always more important than closed issues. If both issue
    // are closed, the one that is most recently created is more important.
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

  String _getTestNameFromBuilderName(String builderName) {
    // The builder names is in the format '<platform> <test name>'.
    final List<String> words = builderName.split(' ');
    return words.length < 2 ? words[0] : words[1];
  }

  String _getTestOwner(String builderName, _BuilderType type, String testOwnersContent) {
    final String testName = _getTestNameFromBuilderName(builderName);
    String owner;
    switch (type) {
      case _BuilderType.shard:
        {
          // The format looks like this:
          //   # build_tests @zanderso @flutter/tool
          final RegExpMatch match = shardTestOwners.firstMatch(testOwnersContent);
          if (match != null && match.namedGroup(kOwnerGroupName) != null) {
            final List<String> lines =
                match.namedGroup(kOwnerGroupName).split('\n').where((String line) => line.contains('@')).toList();

            for (final String line in lines) {
              final List<String> words = line.trim().split(' ');
              // e.g. words = ['#', 'build_test', '@zanderso' '@flutter/tool']
              if (testName.contains(words[1])) {
                owner = words[2].substring(1); // Strip out the lead '@'
                break;
              }
            }
          }
          break;
        }
      case _BuilderType.devicelab:
        {
          // The format looks like this:
          //   /dev/devicelab/bin/tasks/dart_plugin_registry_test.dart @stuartmorgan @flutter/plugin
          final RegExpMatch match = devicelabTestOwners.firstMatch(testOwnersContent);
          if (match != null && match.namedGroup(kOwnerGroupName) != null) {
            final List<String> lines = match
                .namedGroup(kOwnerGroupName)
                .split('\n')
                .where((String line) => line.isNotEmpty || !line.startsWith('#'))
                .toList();

            for (final String line in lines) {
              final List<String> words = line.trim().split(' ');
              // e.g. words = ['/xxx/xxx/xxx_test.dart', '@stuartmorgan' '@flutter/tool']
              if (words[0].endsWith('$testName.dart')) {
                owner = words[1].substring(1); // Strip out the lead '@'
                break;
              }
            }
          }
          break;
        }
      case _BuilderType.frameworkHostOnly:
        {
          // The format looks like this:
          //   # Linux analyze
          //   /dev/bots/analyze.dart @HansMuller @flutter/framework
          final RegExpMatch match = frameworkHostOnlyTestOwners.firstMatch(testOwnersContent);
          if (match != null && match.namedGroup(kOwnerGroupName) != null) {
            final List<String> lines =
                match.namedGroup(kOwnerGroupName).split('\n').where((String line) => line.isNotEmpty).toList();
            int index = 0;
            while (index < lines.length) {
              if (lines[index].startsWith('#') && index + 1 < lines.length) {
                final List<String> commentWords = lines[index].trim().split(' ');
                // e.g. commentWords = ['#', 'Linux' 'analyze']
                index += 1;
                if (lines[index].startsWith('#')) {
                  // The next line should not be a comment. This can happen if
                  // someone adds an additional comment to framework host only
                  // session.
                  continue;
                }
                if (testName.contains(commentWords[2])) {
                  final List<String> ownerWords = lines[index].trim().split(' ');
                  // e.g. ownerWords = ['/xxx/xxx/xxx_test.dart', '@HansMuller' '@flutter/framework']
                  owner = ownerWords[1].substring(1); // Strip out the lead '@'
                  break;
                }
              }
              index += 1;
            }
          }
          break;
        }
      case _BuilderType.unknown:
        break;
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
        lines[nextLine] = lines[nextLine].replaceFirst('false', 'true # Flaky $issueUrl');
        return lines.join('\n');
      }
      nextLine += 1;
    }
    lines.insert(builderLineNumber + 1, '    $_ciYamlTargetIsFlakyKey: true # Flaky $issueUrl');
    return lines.join('\n');
  }

  Future<RepositorySlug> getSlugFor(GitHub client, String repository) async {
    return RepositorySlug((await client.users.getCurrentUser()).login, repository);
  }
}

class _BuilderDetail {
  const _BuilderDetail({
    @required this.statistic,
    @required this.existingIssue,
    @required this.existingPullRequest,
    @required this.isMarkedFlaky,
    @required this.owner,
    @required this.type,
  });
  final BuilderStatistic statistic;
  final Issue existingIssue;
  final PullRequest existingPullRequest;
  final String owner;
  final bool isMarkedFlaky;
  final _BuilderType type;
}

enum _BuilderType {
  devicelab,
  frameworkHostOnly,
  shard,
  unknown,
}

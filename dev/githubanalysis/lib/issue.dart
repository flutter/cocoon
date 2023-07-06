// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:github/github.dart';
import 'package:http/http.dart';

import 'cache.dart';
import 'utils.dart';


const List<String> priorities = <String>['P0', 'P1', 'P2', 'P3'];

class FullIssue {
  FullIssue(this.repo, this.issueNumber, this._metadata, this.comments, this.reactions, { this.redirect, this.isDeleted = false }) {
    _labels = _metadata?.labels.map<String>((final IssueLabel label) => label.name).toSet();
    if (_labels != null) {
      final Set<String> matches = priorities.toSet().intersection(_labels!);
      if (matches.length > 1) {
        print('\nWARNING: Too many priority labels on issue #$issueNumber: ${matches.join(', ')}');
        for (final String priority in priorities) {
          if (matches.contains(priority)) {
            _priority = priority;
            break;
          }
        }
      } else if (matches.length == 1) {
        _priority = matches.single;
      } else {
        _priority = null;
      }
    }
  }

  final RepositorySlug repo;
  final int issueNumber;
  final Issue? _metadata;
  Issue get metadata => _metadata!; // only available when isValid
  final List<IssueComment> comments;
  final List<Reaction> reactions;
  final String? redirect; // not null when metadata == null && !isDeleted
  final bool isDeleted;

  late final Set<String>? _labels;
  Set<String> get labels => _labels!; // only available when isValid

  late final String? _priority;
  String? get priority => _priority; // only available when isValid

  bool get isValid => _metadata != null;
  bool get isPullRequest => _metadata?.pullRequest != null;

  static Future<FullIssue> load({
    required final Directory cache,
    required final GitHub github,
    required final RepositorySlug repo,
    required final int issueNumber,
    final DateTime? cacheEpoch,
  }) async {
    final String cacheData = await loadFromCache(cache, github, <String>['issue', repo.owner, repo.name, issueNumber.toString()], cacheEpoch, () async {
      try {
        final Issue issue = await github.issues.get(repo, issueNumber);
        if (issue.url.startsWith(github.endpoint)) {
          if (issue.url != '${github.endpoint}/repos/$repo/issues/$issueNumber') {
            return json.encode(<String, Object?>{ 'redirect': issue.url });
          }
        } else if (issue.url == '') {
          return json.encode(<String, Object?>{ 'deleted': true });
        }
        final List<IssueComment> comments = await github.issues.listCommentsByIssue(repo, issueNumber).toList();
        final List<Reaction> reactions = await github.issues.listReactions(repo, issueNumber).toList();
        return json.encode(<String, Object?>{ 'issue': issue, 'comments': comments, 'reactions': reactions });
      } on ClientException catch (e) {
        // print('\nIssue $issueNumber is a problem child (treating as deleted): $e');
        return json.encode(<String, Object?>{ 'deleted': true, 'error': e.toString() });
      }
    });
    final Map<String, Object?> data = json.decode(cacheData)! as Map<String, Object?>;
    if (data['redirect'] != null) {
      return FullIssue(repo, issueNumber, null, const <IssueComment>[], const <Reaction>[], redirect: data['redirect']! as String);
    }
    if (data['deleted'] == true) {
      return FullIssue(repo, issueNumber, null, const <IssueComment>[], const <Reaction>[], isDeleted: true);
    }
    final Issue issue = Issue.fromJson(data['issue']! as Map<String, Object?>);
    return FullIssue(
      repo,
      issueNumber,
      issue,
      (data['comments']! as List<Object?>)
        .cast<Map<String, Object?>>()
        .map<IssueComment>(IssueComment.fromJson)
        .toList(),
      (data['reactions']! as List<Object?>)
        .cast<Map<String, Object?>>()
        .map<Reaction>(Reaction.fromJson)
        .toList(),
    );
  }

  @override
  String toString() {
    final StringBuffer result = StringBuffer();
    if (isValid) {
      result
        ..writeln('Issue $issueNumber (${metadata.state}): ${metadata.title}')
        ..writeln(metadata.htmlUrl)
        ..writeln('Created by ${metadata.user!.login} on ${metadata.createdAt}, last updated on ${metadata.updatedAt}.');
      if (metadata.isClosed) {
        result.writeln('Closed by ${metadata.closedBy?.login} on ${metadata.closedAt}.');
        if (metadata.closedBy != null) {
          final User user = metadata.closedBy!;
          result
            ..writeln('  avatarUrl: ${user.avatarUrl}')
            ..writeln('  bio: ${user.bio}')
            ..writeln('  blog: ${user.blog}')
            ..writeln('  company: ${user.company}')
            ..writeln('  createdAt: ${user.createdAt}')
            ..writeln('  email: ${user.email}')
            ..writeln('  followersCount: ${user.followersCount}')
            ..writeln('  followingCount: ${user.followingCount}')
            ..writeln('  hirable: ${user.hirable}')
            ..writeln('  htmlUrl: ${user.htmlUrl}')
            ..writeln('  id: ${user.id}')
            ..writeln('  location: ${user.location}')
            ..writeln('  login: ${user.login}')
            ..writeln('  name: ${user.name}')
            ..writeln('  publicGistsCount: ${user.publicGistsCount}')
            ..writeln('  publicReposCount: ${user.publicReposCount}')
            ..writeln('  siteAdmin: ${user.siteAdmin}')
            ..writeln('  twitterUsername: ${user.twitterUsername}')
            ..writeln('  updatedAt: ${user.updatedAt}');
        }
      }
      if (isPullRequest) {
        result.writeln('  Pull request: ${metadata.pullRequest?.diffUrl}');
      }
      result
        ..writeln('Assignees: ${metadata.assignees!.map((final User user) => user.login!).join(', ')}')
        ..writeln('Labels: ${metadata.labels.map((final IssueLabel label) => label.name).join(', ')}')
        ..writeln('Milestone: ${metadata.milestone ?? ""}');
    } else {
      result.writeln('Issue $issueNumber (redirected): see $redirect');
    }
    for (final IssueComment comment in comments) {
      final String line = comment.body!.split('\n').first;
      final String body = line.substring(0, math.min(40, line.length));
      result.writeln('Comment by ${comment.user!.login} at ${comment.createdAt}: $body');
    }
    for (final Reaction reaction in reactions) {
      result.writeln('Reaction: ${reaction.user!.login} ${reaction.content} at ${reaction.createdAt}');
    }
    return result.toString();
  }
}

Future<void> fetchAllIssues(final GitHub github, final Directory cache, final RepositorySlug repo, final Duration issueMaxAge, final Map<int, FullIssue> results) async {
  int index = 1;
  int issues = 0;
  int prs = 0;
  int invalid = 0;
  final File lastIssueNumberFile = cacheFileFor(cache, <String>['issue', repo.owner, repo.name, 'last']);
  int lastIssueNumber = await readFromFile<int>(lastIssueNumberFile, int.tryParse) ?? 0;
  bool maxKnown = false;
  while (true) {
    try {
      final FullIssue issue = await FullIssue.load(
        cache: cache,
        github: github,
        repo: repo,
        issueNumber: index,
        cacheEpoch: maxAge(issueMaxAge),
      );
      if (issue.isValid) {
        if (issue.isPullRequest) {
          prs += 1;
        } else {
          issues += 1;
        }
      } else if (issue.isDeleted) {
        throw NotFound(github, 'Issue $index deleted or not yet filed.');
      } else {
        // probably redirect
        invalid += 1;
      }
      results[index] = issue;
    } on FormatException catch (e) {
      print('\nIssue $index could not be processed: $e');
      invalid += 1;
    } on NotFound {
      if (index > lastIssueNumber) {
        final Issue lastIssue = await github.issues.listByRepo(repo, state: 'all', sort: 'created', direction: 'desc').first;
        lastIssueNumber = lastIssue.number;
        maxKnown = true;
        if (index > lastIssueNumber) {
          break;
        }
        invalid += 1;
      }
    }
    await rateLimit(github, '${repo.fullName}: #$index${ lastIssueNumber > 0 ? " of ${maxKnown ? "" : "~"}$lastIssueNumber" : ""} ($issues issues; $prs PRs; $invalid errors)', 'issue #${index + 1}');
    index += 1;
  }
  await lastIssueNumberFile.writeAsString(lastIssueNumber.toString());
  stdout.write('\x1B[K\r');
}

Future<void> updateAllIssues(final GitHub github, final Directory cache, final RepositorySlug repo, final Map<int, FullIssue> issues) async {
  final Set<int> pendingIssues = issues.isEmpty ? <int>{} : issues.keys.toSet();
  int highestKnownIssue = pendingIssues.isEmpty ? 0 : (pendingIssues.toList()..sort()).last;
  final File updateStampFile = cacheFileFor(cache, <String>['issue', repo.owner, repo.name, 'last-update']);
  final DateTime? lastFullScanStartTime = await readFromFile<DateTime>(updateStampFile, DateTime.tryParse);
  DateTime? thisFullScanStartTime;
  int count = 0;
  await rateLimit(github, '${repo.fullName}: fetching issues with recent changes', 'scan');
  await for (final Issue summary in github.issues.listByRepo(repo, state: 'all', sort: 'updated', direction: 'desc', perPage: 100)) {
    if (summary.updatedAt != null) {
      thisFullScanStartTime ??= summary.updatedAt!;
    }
    if (mode == Mode.abbreviated && summary.updatedAt != null && lastFullScanStartTime != null && summary.updatedAt!.isBefore(lastFullScanStartTime)) {
      stdout.write('\x1B[K\r');
      return;
    }
    const int maxRetry = 5;
    for (int retry = 1; retry <= maxRetry; retry += 1) {
      try {
        final String parenthetical;
        Duration? delta = lastFullScanStartTime?.difference(summary.updatedAt!);
        if (delta != null && delta.inMilliseconds < 0) {
          delta = -delta;
          if (delta.inDays > 2) {
            parenthetical = '${delta.inDays} days remaining';
          } else if (delta.inHours > 2) {
            parenthetical = '${delta.inHours} hours remaining';
          } else if (delta.inMinutes > 2) {
            parenthetical = '${delta.inMinutes} minutes remaining';
          } else {
            parenthetical = '${delta.inMilliseconds}ms remaining';
          }
        } else {
          parenthetical = '${100 * count ~/ (pendingIssues.length + count)}% newer than ${summary.updatedAt}';
        }
        await rateLimit(github, '${repo.fullName}: $count issues updated ($parenthetical)', 'scan');
        final FullIssue issue = await FullIssue.load(
          cache: cache,
          github: github,
          repo: repo,
          issueNumber: summary.number,
          cacheEpoch: summary.updatedAt,
        );
        assert(!issue.isValid || !issue.metadata.updatedAt!.isBefore(summary.updatedAt!), 'invariant violation\nOLD DATA:\n${json.encode(issue.metadata.toJson())}\nNEW DATA:\n${json.encode(summary.toJson())}');
        if (issue.issueNumber > highestKnownIssue) {
          for (int index = highestKnownIssue; index < issue.issueNumber; index += 1) {
            pendingIssues.add(index);
          }
          highestKnownIssue = issue.issueNumber;
        } else {
          pendingIssues.remove(issue.issueNumber);
        }
        issues[issue.issueNumber] = issue;
        break;
      } on FormatException catch (e) {
        print('\nError while updating issue #${summary.number} (attempt $retry/$maxRetry): $e');
      }
    }
    count += 1;
  }
  stdout.write('\x1B[K\r');
  if (pendingIssues.isNotEmpty) {
    // looks like these went away, so force fetch them
    int count = 0;
    for (final int issueNumber in pendingIssues) {
      await rateLimit(github, '${repo.fullName}: $count / ${pendingIssues.length} missing issues checked', 'issue #$issueNumber');
      try {
        issues[issueNumber] = await FullIssue.load(
          cache: cache,
          github: github,
          repo: repo,
          issueNumber: issueNumber,
          cacheEpoch: lastFullScanStartTime,
        );
        count += 1;
      } on Exception catch (e) {
        print('\nError while updating issue #$issueNumber: $e');
      }
    }
    stdout.write('\x1B[K\r');
  }
  if (thisFullScanStartTime != null) {
    await updateStampFile.writeAsString(thisFullScanStartTime.toIso8601String());
  }
}

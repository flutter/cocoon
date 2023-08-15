// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:github/github.dart';
import 'package:http/http.dart';

import 'debug_http.dart';
import 'issue.dart';
import 'team.dart';
import 'utils.dart';

const bool _debugNetwork = false;

// File that contains OAuth token obtained via https://github.com/settings/personal-access-tokens/new
// + Resource owner "flutter"
// + Public Repositories (read-only)
// + Organization permissions -> Members -> Read-only
final File tokenFile = File('.github-token');
final File membersFile = File('members.txt');
final File exmembersFile = File('exmembers.txt');

final Directory cache = Directory('cache');
final Directory output = Directory('output');
const String orgName = 'flutter';
final RepositorySlug issueDatabaseRepo = RepositorySlug(orgName, 'flutter');
final Set<RepositorySlug> repos = <RepositorySlug>{
  issueDatabaseRepo,
  RepositorySlug(orgName, 'engine'),
  RepositorySlug(orgName, 'buildroot'),
  RepositorySlug(orgName, 'devtools'),
  RepositorySlug(orgName, 'flutter-intellij'),
  RepositorySlug(orgName, 'packages'),
  RepositorySlug(orgName, 'codelabs'),
  RepositorySlug(orgName, 'website'),
  RepositorySlug(orgName, 'cocoon'),
  RepositorySlug(orgName, 'platform_tests'),
  RepositorySlug(orgName, 'samples'),
  RepositorySlug(orgName, 'gallery'),
  RepositorySlug(orgName, 'news_toolkit'),
  RepositorySlug(orgName, 'holobooth'),
  RepositorySlug(orgName, 'pinball'),
  RepositorySlug(orgName, 'photobooth'),
};
const String primaryTeam = 'flutter-hackers';
const Duration rosterMaxAge = Duration(minutes: 10);
const Duration issueMaxAge = Duration(days: 365);

const Set<String> csvSpecials = <String>{'\'', '"', ',', '\n'};

Future<int> full(final Directory cache, final GitHub github) async {
  try {
    // FETCH USER AND TEAM DATA
    print('Team roster...');
    final TeamRoster roster = await TeamRoster.load(
      cache: cache,
      github: github,
      orgName: orgName,
      cacheEpoch: maxAge(rosterMaxAge),
    );
    final Set<String> allMembers = <String>{};
    final Set<String> currentMembers = roster.teams[primaryTeam]!.keys.toSet();
    final Set<String> expectedMembers = (await membersFile.readAsString())
        .trimRight()
        .split('\n')
        .where((final String name) => !name.endsWith(' (DO NOT ADD)'))
        .toSet();
    final Set<String> expectedExmembers = (await exmembersFile.readAsString()).trimRight().split('\n').toSet();
    try {
      Set<String> canon(final Set<String> set) => set.map<String>((final String s) => s.toLowerCase()).toSet();
      final Set<String> unexpectedMembers = canon(currentMembers).difference(canon(expectedMembers));
      final Set<String> memberExmembers = canon(expectedExmembers).intersection(canon(currentMembers));
      final Set<String> missingMembers = canon(expectedMembers).difference(canon(currentMembers));
      if (unexpectedMembers.isNotEmpty) {
        print(
            'WARNING: The following users are currently members of $primaryTeam but not expected: ${unexpectedMembers.join(', ')}');
      }
      if (memberExmembers.isNotEmpty) {
        print(
            'WARNING: The following users are currently members of $primaryTeam but should have been removed: ${memberExmembers.join(', ')}');
      }
      if (missingMembers.isNotEmpty) {
        print(
            'WARNING: The following users are currently NOT members of $primaryTeam but were expected:\n  ${missingMembers.join('\n  ')}');
      }
      allMembers
        ..addAll(currentMembers)
        ..addAll(expectedMembers)
        ..addAll(expectedExmembers);
    } on FileSystemException catch (e) {
      if (membersFile.existsSync()) {
        print('Unable to read ${membersFile.path}: ${e.message}');
        return 1;
      }
    }
    for (final String? teamName in roster.teams.keys.where((final String? team) => team != null)) {
      for (final String userName in roster.teams[teamName]!.keys) {
        if (!roster.teams[null]!.containsKey(userName)) {
          print('WARNING: user $userName is in $teamName but not in organization.');
        }
      }
    }

    // FETCH ACTIVITY
    print('');
    print('Fetching issues...');
    final Map<String, Map<int, FullIssue>> issues = <String, Map<int, FullIssue>>{};
    try {
      for (final RepositorySlug repo in repos) {
        await fetchAllIssues(github, cache, repo, issueMaxAge, issues[repo.fullName] = <int, FullIssue>{});
      }
      print('Updating issues...');
      for (final RepositorySlug repo in repos) {
        await updateAllIssues(github, cache, repo, issues[repo.fullName]!);
      }
    } on Abort {} // ignore: empty_catches

    // ANALYZE ACTIVITY RESULTS
    print('');
    print('Analyzing...');
    try {
      await output.create(recursive: true);
    } on FileSystemException catch (e) {
      print('Unable to create output in "${output.path}": $e');
      return 1;
    }
    final Map<String, UserActivity> activityMetrics = <String, UserActivity>{};
    UserActivity forUser(final User? user) {
      return activityMetrics.putIfAbsent(user!.login!, () {
        final UserActivity result = UserActivity();
        if (expectedMembers.contains(user.login)) {
          result
            ..isMember = true
            ..isActiveMember = true;
        } else if (expectedExmembers.contains(user.login)) {
          result.isMember = true;
        }
        return result;
      });
    }

    final Set<String> reactionKinds = <String>{};
    final Set<String?> foundPriorities = <String?>{};
    void increment<T>(final Map<T, int> map, final Set<T> keys, final T key) {
      keys.add(key);
      if (map.containsKey(key)) {
        map[key] = map[key]! + 1;
      } else {
        map[key] = 1;
      }
    }

    void processText(final UserActivity activity, final String body) {
      activity.characters += body.length;
    }

    for (final String user in currentMembers) {
      forUser(User(login: user));
    }
    final List<FullIssue> allIssues = issues.values
        .expand((final Map<int, FullIssue> issues) => issues.values)
        .where((final FullIssue issue) => issue.isValid)
        .toList();
    for (final FullIssue issue in allIssues) {
      if (issue.isPullRequest) {
        forUser(issue.metadata.user).pullRequests.add(issue.metadata.createdAt);
      } else {
        forUser(issue.metadata.user).issues.add(issue.metadata.createdAt);
        increment<String?>(forUser(issue.metadata.user).priorityCount, foundPriorities, issue.priority);
      }
      if (!issue.isPullRequest && (issue.metadata.closedBy != null)) {
        forUser(issue.metadata.closedBy).closures.add(issue.metadata.closedAt);
        if (issue.metadata.closedBy!.login == issue.metadata.user!.login) {
          forUser(issue.metadata.closedBy).selfClosures += 1;
        }
      }
      processText(forUser(issue.metadata.user), issue.metadata.body);
      for (final IssueComment comment in issue.comments) {
        forUser(comment.user).comments.add(comment.createdAt);
        processText(forUser(comment.user), comment.body!);
      }
      for (final Reaction reaction in issue.reactions) {
        forUser(reaction.user).reactions.add(reaction.createdAt);
        increment(forUser(reaction.user).reactionCount, reactionKinds, reaction.content!);
      }
    }
    DateTime? earliest;
    DateTime? latest;
    void considerTimes(final UserActivity activity, final List<DateTime?> times) {
      for (final DateTime? time in times) {
        if (activity.earliest == null || (time != null && time.isBefore(activity.earliest!))) {
          activity.earliest = time;
        }
        if (activity.latest == null || (time != null && time.isAfter(activity.latest!))) {
          activity.latest = time;
        }
        if (earliest == null || (time != null && time.isBefore(earliest!))) {
          earliest = time;
        }
        if (latest == null || (time != null && time.isAfter(latest!))) {
          latest = time;
        }
      }
    }

    for (final UserActivity activity in activityMetrics.values) {
      considerTimes(activity, activity.issues);
      considerTimes(activity, activity.comments);
      considerTimes(activity, activity.closures);
      considerTimes(activity, activity.pullRequests);
      considerTimes(activity, activity.reactions);
    }

    // PRINT ACTIVITY RESULTS
    final StringBuffer summary = StringBuffer();
    for (final String reactionKind in reactionKinds) {
      verifyStringSanity(reactionKind, csvSpecials);
    }
    final List<String> sortedReactionKinds = reactionKinds.toList()..sort();
    summary.writeln(
        'user,is member,is active member,earliest,latest,days active,total,density,issues,comments,closures,self closures,pull requests,characters,missing priority,${priorities.join(',')},reactions,${sortedReactionKinds.join(',')}');
    int usersWithMoreThanOneDayActive = 0;
    for (final String user in activityMetrics.keys.toList()
      ..sort((final String a, final String b) => activityMetrics[b]!.total - activityMetrics[a]!.total)) {
      verifyStringSanity(user, csvSpecials);
      final UserActivity activity = activityMetrics[user]!;
      if (activity.daysActive > 0) {
        usersWithMoreThanOneDayActive += 1;
      }
      summary.write(
          '$user,${activity.isMember},${activity.isActiveMember},${activity.earliest},${activity.latest},${activity.daysActive},${activity.total},${activity.density},${activity.issues.length},${activity.comments.length},${activity.closures.length},${activity.selfClosures},${activity.pullRequests.length},${activity.characters},${activity.priorityCount[null] ?? 0}');
      for (final String priority in priorities) {
        summary.write(',${activity.priorityCount[priority] ?? 0}');
      }
      summary.write(',${activity.reactions.length}');
      for (final String reactionKind in sortedReactionKinds) {
        summary.write(',${activity.reactionCount[reactionKind] ?? 0}');
      }
      summary.writeln();
    }
    await File('${output.path}/users.csv').writeAsString(summary.toString());
    print('Total participants: ${activityMetrics.length}');
    print('Participants with more than one day of activity: $usersWithMoreThanOneDayActive');
    print('User activity results stored in: ${output.path}/users.csv');

    // ANALYZE PRIORITIES
    final Map<String, PriorityResults> priorityAnalysis = <String, PriorityResults>{};
    for (final String priority in priorities) {
      priorityAnalysis[priority] = PriorityResults();
    }
    final List<FullIssue> primaryIssues = issues[issueDatabaseRepo.fullName]!
        .values
        .where((final FullIssue issue) => issue.isValid && !issue.isPullRequest)
        .toList();
    final List<FullIssue> primaryPRs = issues[issueDatabaseRepo.fullName]!
        .values
        .where((final FullIssue issue) => issue.isValid && issue.isPullRequest)
        .toList();
    for (final FullIssue issue in primaryIssues.where((final FullIssue issue) => issue.priority != null)) {
      final PriorityResults priorityResults = priorityAnalysis[issue.priority!]!;
      final bool teamIssue = allMembers.contains(issue.metadata.user!.login);
      priorityResults.total += 1;
      if (teamIssue) {
        priorityResults.openedByTeam += 1;
      } else {
        priorityResults.openedByNonTeam += 1;
      }
      if (issue.metadata.isOpen) {
        priorityResults.open += 1;
      } else {
        priorityResults.closed += 1;
        if (issue.metadata.closedAt == null || issue.metadata.createdAt == null) {
          print(
              'WARNING: bogus open/close timeline data in ${issue.issueNumber}: opened at ${issue.metadata.createdAt}, closed at ${issue.metadata.closedAt}');
        } else {
          final Duration timeOpen = issue.metadata.closedAt!.difference(issue.metadata.createdAt!);
          priorityResults.timeOpen.add(timeOpen);
        }
        if (teamIssue) {
          priorityResults.openedByTeamAndClosed += 1;
        } else {
          priorityResults.openedByNonTeamAndClosed += 1;
        }
      }
    }

    // PRINT PRIORITY RESULTS
    summary
      ..clear()
      ..writeln(
          'priority,total,open,closed,openedByTeam,openedByNonTeam,openedByTeamAndClosed,openedByNonTeamAndClosed,meanTimeOpen,p01TimeOpen,p05TimeOpen,medianTimeOpen,p95TimeOpen,p99TimeOpen');
    for (final String priority in priorities) {
      verifyStringSanity(priority, csvSpecials);
      final PriorityResults entry = priorityAnalysis[priority]!;
      summary.write(
          '$priority,${entry.total},${entry.open},${entry.closed},${entry.openedByTeam},${entry.openedByNonTeam},${entry.openedByTeamAndClosed},${entry.openedByNonTeamAndClosed},');
      if (entry.timeOpen.isEmpty) {
        summary.write('NaN,NaN,NaN,NaN');
      } else {
        entry.timeOpen.sort();
        summary
          ..write(
              '${entry.timeOpen.fold<int>(0, (final int sum, final Duration t) => sum + t.inMilliseconds) / (entry.timeOpen.length * Duration.millisecondsPerDay)},')
          ..write(
              '${entry.timeOpen[(entry.timeOpen.length * 0.01).floor()].inMilliseconds / Duration.millisecondsPerDay},')
          ..write(
              '${entry.timeOpen[(entry.timeOpen.length * 0.05).floor()].inMilliseconds / Duration.millisecondsPerDay},');
        if (entry.timeOpen.length > 1) {
          final Duration median1 = entry.timeOpen[(entry.timeOpen.length / 2.0).floor()];
          final Duration median2 = entry.timeOpen[(entry.timeOpen.length / 2.0).ceil()];
          summary.write('${(median1.inMilliseconds + median2.inMilliseconds) / (2.0 * Duration.millisecondsPerDay)},');
        } else {
          summary.write('${(entry.timeOpen.first.inMilliseconds) / Duration.millisecondsPerDay},');
        }
        summary
          ..write(
              '${entry.timeOpen[(entry.timeOpen.length * 0.95).floor()].inMilliseconds / Duration.millisecondsPerDay},')
          ..write(
              '${entry.timeOpen[(entry.timeOpen.length * 0.99).floor()].inMilliseconds / Duration.millisecondsPerDay},');
      }
      summary.writeln();
    }
    await File('${output.path}/priorities.csv').writeAsString(summary.toString());
    print('Priority results stored in: ${output.path}/priorities.csv');

    // PRINT ISSUE DATA
    int deadCount = 0;
    int zombieCount = 0;
    summary
      ..clear()
      ..writeln(
          'repository,issue,state,createdAt,createdBy,closedAt,closedBy,timeOpen,updatedAt,priority,labelCount,commentCount,${sortedReactionKinds.join(',')},daysToTwentyVotes,isNewFeature,isProposal,isPendingAutoclosure,isFiledByTeam,isFiledByExMember,');
    for (final FullIssue issue in allIssues.where((final FullIssue issue) => !issue.isPullRequest)) {
      verifyStringSanity(issue.metadata.state, csvSpecials);
      summary.write(
          '${issue.repo.fullName},${issue.issueNumber},${issue.metadata.state},${issue.metadata.createdAt},${issue.metadata.user!.login},${issue.metadata.closedAt},${issue.metadata.closedBy?.login ?? (issue.isValid && issue.metadata.isClosed ? "<unknown>" : "")},${issue.isValid && issue.metadata.isClosed ? issue.metadata.closedAt!.difference(issue.metadata.createdAt!).inMilliseconds / Duration.millisecondsPerDay : ""},${issue.metadata.updatedAt},${issue.priority ?? ""},${issue.labels.length},${issue.comments.length}');
      for (final String reactionKind in sortedReactionKinds) {
        int count = 0;
        for (final Reaction reaction in issue.reactions) {
          if (reaction.content == reactionKind) {
            count += 1;
          }
        }
        summary.write(',$count');
      }
      int count = 0;
      int? daysToTwentyVotes;
      for (final Reaction reaction in issue.reactions) {
        if (reaction.content == '+1') {
          count += 1;
          if (count >= 20) {
            daysToTwentyVotes = reaction.createdAt!.difference(issue.metadata.createdAt!).inDays;
            break;
          }
        }
      }
      summary
        ..write(',${daysToTwentyVotes ?? ''}')
        ..write(',${issue.labels.contains('new feature')}')
        ..write(',${issue.labels.contains('proposal')}')
        ..write(',${issue.labels.contains('waiting for customer response')}')
        ..write(',${allMembers.contains(issue.metadata.user!.login)}')
        ..write(',${expectedExmembers.contains(issue.metadata.user!.login)}')
        ..writeln();
      if ((daysToTwentyVotes == null || daysToTwentyVotes > 60) &&
          issue.labels.contains('new feature') &&
          (issue.metadata.isOpen || issue.metadata.closedAt!.difference(issue.metadata.createdAt!).inDays > 60)) {
        if (issue.metadata.isOpen) {
          deadCount += 1;
        } else {
          zombieCount += 1;
        }
      }
    }
    await File('${output.path}/issues.csv').writeAsString(summary.toString());
    print('Issue summaries stored in: ${output.path}/issues.csv');
    print('$deadCount issues would be closed; $zombieCount issues would not have been fixed.');

    // COLLECT CLOSE TIME PERCENTILES
    int maxDaysToClose = 0;
    final Map<int, Map<String?, int>> closureTimeHistogramClosed = <int, Map<String?, int>>{};
    final Map<String?, int> closureTimeTotalsClosed = <String?, int>{
      null: 0,
      for (final String priority in priorities) priority: 0,
    };
    for (final FullIssue issue in primaryIssues.where((final FullIssue issue) => issue.metadata.isClosed)) {
      final int timeOpen = issue.metadata.closedAt!.difference(issue.metadata.createdAt!).inDays;
      final String? priority = issue.priority;
      closureTimeHistogramClosed.putIfAbsent(timeOpen, () => <String?, int>{}).update(
            priority,
            (final int value) => value + 1,
            ifAbsent: () => 1,
          );
      closureTimeTotalsClosed[priority] = closureTimeTotalsClosed[priority]! + 1;
      if (timeOpen > maxDaysToClose) {
        maxDaysToClose = timeOpen;
      }
    }

    // PRINT CLOSE TIME PERCENTILES OF CLOSED BUGS
    summary
      ..clear()
      ..writeln(
          'time to close (days),unprioritized,${priorities.where((final String priority) => closureTimeTotalsClosed[priority]! > 0).join(",")},unprioritized,${priorities.where((final String priority) => closureTimeTotalsClosed[priority]! > 0).join(",")}');
    if (closureTimeTotalsClosed[null]! > 0) {
      final Map<String?, int> closureTimeCumulativeSum = <String?, int>{
        null: 0,
        for (final String priority in priorities)
          if (closureTimeTotalsClosed[priority]! > 0) priority: 0,
      };
      for (int day = 0; day <= maxDaysToClose; day += 1) {
        if (closureTimeHistogramClosed.containsKey(day)) {
          if (closureTimeHistogramClosed[day]!.containsKey(null)) {
            closureTimeCumulativeSum[null] = closureTimeCumulativeSum[null]! + closureTimeHistogramClosed[day]![null]!;
          }
          for (final String priority in priorities) {
            if (closureTimeHistogramClosed[day]!.containsKey(priority)) {
              closureTimeCumulativeSum[priority] =
                  closureTimeCumulativeSum[priority]! + closureTimeHistogramClosed[day]![priority]!;
            }
          }
        }
        summary.write('$day,${closureTimeCumulativeSum[null]}');
        for (final String priority in priorities) {
          if (closureTimeTotalsClosed[priority]! > 0) {
            summary.write(',${closureTimeCumulativeSum[priority]}');
          }
        }
        summary.write(',${100.0 * closureTimeCumulativeSum[null]! / closureTimeTotalsClosed[null]!}%');
        for (final String priority in priorities) {
          if (closureTimeTotalsClosed[priority]! > 0) {
            summary.write(',${100.0 * closureTimeCumulativeSum[priority]! / closureTimeTotalsClosed[priority]!}%');
          }
        }
        summary.writeln();
      }
    }
    await File('${output.path}/priority-percentiles.csv').writeAsString(summary.toString());
    print('Priority percentiles stored in: ${output.path}/priority-percentiles.csv');

    // COLLECT CLOSE TIME PERCENTILES OF ALL BUGS
    final Map<int, Map<String?, int>> closureTimeHistogramAll = <int, Map<String?, int>>{};
    final Map<String?, int> closureTimeTotalsAll = <String?, int>{
      null: 0,
      for (final String priority in priorities) priority: 0,
    };
    for (final FullIssue issue in primaryIssues) {
      final String? priority = issue.priority;
      closureTimeTotalsAll[priority] = closureTimeTotalsAll[priority]! + 1;
      final int timeOpen = issue.metadata.isClosed
          ? issue.metadata.closedAt!.difference(issue.metadata.createdAt!).inDays
          : maxDaysToClose + 1;
      closureTimeHistogramAll.putIfAbsent(timeOpen, () => <String?, int>{}).update(
            priority,
            (final int value) => value + 1,
            ifAbsent: () => 1,
          );
    }

    // PRINT CLOSE TIME PERCENTILES OF ALL BUGS
    summary
      ..clear()
      ..writeln(
          'time to close (days),unprioritized,${priorities.where((final String priority) => closureTimeTotalsAll[priority]! > 0).join(",")},unprioritized,${priorities.where((final String priority) => closureTimeTotalsAll[priority]! > 0).join(",")}');
    if (closureTimeTotalsAll[null]! > 0) {
      final Map<String?, int> closureTimeCumulativeSum = <String?, int>{
        null: 0,
        for (final String priority in priorities)
          if (closureTimeTotalsAll[priority]! > 0) priority: 0,
      };
      for (int day = 0; day <= maxDaysToClose + 1; day += 1) {
        if (closureTimeHistogramAll.containsKey(day)) {
          if (closureTimeHistogramAll[day]!.containsKey(null)) {
            closureTimeCumulativeSum[null] = closureTimeCumulativeSum[null]! + closureTimeHistogramAll[day]![null]!;
          }
          for (final String priority in priorities) {
            if (closureTimeHistogramAll[day]!.containsKey(priority)) {
              closureTimeCumulativeSum[priority] =
                  closureTimeCumulativeSum[priority]! + closureTimeHistogramAll[day]![priority]!;
            }
          }
        }
        summary.write('$day,${closureTimeCumulativeSum[null]}');
        for (final String priority in priorities) {
          if (closureTimeTotalsAll[priority]! > 0) {
            summary.write(',${closureTimeCumulativeSum[priority]}');
          }
        }
        summary.write(',${100.0 * closureTimeCumulativeSum[null]! / closureTimeTotalsAll[null]!}%');
        for (final String priority in priorities) {
          if (closureTimeTotalsAll[priority]! > 0) {
            summary.write(',${100.0 * closureTimeCumulativeSum[priority]! / closureTimeTotalsAll[priority]!}%');
          }
        }
        summary.writeln();
      }
    }
    await File('${output.path}/priority-percentiles-all.csv').writeAsString(summary.toString());
    print('Priority percentiles stored in: ${output.path}/priority-percentiles-all.csv');

    // PRINT PR DATA
    summary
      ..clear()
      ..writeln('repository,pr,user,state,createdAt,closedAt,timeOpen,updatedAt,labelCount,commentCount,${sortedReactionKinds.join(',')}');
    for (final FullIssue issue in allIssues.where((final FullIssue issue) => issue.isPullRequest)) {
      verifyStringSanity(issue.metadata.state, csvSpecials);
      summary.write('${issue.repo.fullName},${issue.issueNumber},${issue.metadata.user!.login},${issue.metadata.state},${issue.metadata.createdAt},${issue.metadata.closedAt},${issue.metadata.isClosed ? issue.metadata.closedAt!.difference(issue.metadata.createdAt!).inMilliseconds / Duration.millisecondsPerDay : ""},${issue.metadata.updatedAt},${issue.labels.length},${issue.comments.length}');
      for (final String reactionKind in sortedReactionKinds) {
        int count = 0;
        for (final Reaction reaction in issue.reactions) {
          if (reaction.content == reactionKind) {
            count += 1;
          }
        }
        summary.write(',$count');
      }
      summary.writeln();
    }
    await File('${output.path}/prs.csv').writeAsString(summary.toString());
    print('PR summaries stored in: ${output.path}/prs.csv');

    // PRINT USERS
    final List<String> teamNames = roster.teams.keys.where((final String? name) => name != null).cast<String>().toList()
      ..sort();
    final List<String> userNames = roster.teams[null]!.keys.toList()..sort();
    summary
      ..clear()
      ..writeln('user,${teamNames.join(',')}');
    for (final String userName in userNames) {
      verifyStringSanity(userName, csvSpecials);
      summary.write(userName);
      for (final String? teamName in teamNames) {
        summary.write(',');
        if (roster.teams[teamName]!.containsKey(userName)) {
          summary.write('1');
        } else {
          summary.write('0');
        }
      }
      summary.writeln();
    }
    await File('${output.path}/teams.csv').writeAsString(summary.toString());
    print('Team membership summaries stored in: ${output.path}/teams.csv');

    // WEEKLY ACTIVITY OVER TIME
    if (earliest != null) {
      assert(latest != null, 'invariant violation');
      const int window = Duration.millisecondsPerDay * 7;
      final int firstWeekStart = earliest!.millisecondsSinceEpoch ~/ window;
      final List<WeekActivity> weeks = List<WeekActivity>.generate(
        1 + (latest!.millisecondsSinceEpoch ~/ window) - firstWeekStart,
        (final int index) => WeekActivity(
            DateTime.fromMillisecondsSinceEpoch((index + firstWeekStart) * window), reactionKinds, priorities),
      );
      WeekActivity? forWeek(final DateTime? time) {
        if (time == null) {
          return null;
        }
        return weeks[(time.millisecondsSinceEpoch ~/ window) - firstWeekStart];
      }

      for (final FullIssue issue in allIssues) {
        if (!issue.isValid) {
          continue;
        }
        if (issue.isPullRequest) {
          forWeek(issue.metadata.createdAt)!.pullRequests += 1;
        } else {
          forWeek(issue.metadata.createdAt)!.issues += 1;
          forWeek(issue.metadata.createdAt)!.priorityCount[issue.priority] =
              forWeek(issue.metadata.createdAt)!.priorityCount[issue.priority]! + 1;
          if (issue.metadata.isOpen) {
            forWeek(issue.metadata.createdAt)!.remainingIssues += 1;
          }
        }
        if (!issue.isPullRequest && (issue.metadata.closedBy != null)) {
          forWeek(issue.metadata.closedAt)?.closures += 1;
          if (issue.metadata.closedBy!.login == issue.metadata.user!.login) {
            forWeek(issue.metadata.closedAt)?.selfClosures += 1;
          }
        }
        forWeek(issue.metadata.createdAt)?.characters += issue.metadata.body.length;
        for (final IssueComment comment in issue.comments) {
          forWeek(comment.createdAt)!.comments += 1;
          forWeek(comment.createdAt)!.characters += comment.body!.length;
        }
        for (final Reaction reaction in issue.reactions) {
          forWeek(reaction.createdAt)!.reactions += 1;
          forWeek(reaction.createdAt)!.reactionCount[reaction.content!] =
              forWeek(reaction.createdAt)!.reactionCount[reaction.content!]! + 1;
        }
      }
      if (weeks.isNotEmpty) {
        weeks.removeLast(); // last week is incomplete data
      }

      // PRINT WEEKLY ACTIVITY
      summary
        ..clear()
        ..writeln(
            'week,total,issues,remaining issues,closures,self closures,net issues opened,comments,pull requests,characters,missing priority,${priorities.join(',')},reactions,${sortedReactionKinds.join(',')}');
      for (final WeekActivity week in weeks) {
        verifyStringSanity(week.start.toIso8601String(), csvSpecials);
        summary.write(
            '${week.start},${week.total},${week.issues},${week.remainingIssues},${week.closures},${week.selfClosures},${week.issues - week.closures},${week.comments},${week.pullRequests},${week.characters},${week.priorityCount[null]!}');
        for (final String priority in priorities) {
          summary.write(',${week.priorityCount[priority]!}');
        }
        summary.write(',${week.reactions}');
        for (final String reactionKind in sortedReactionKinds) {
          summary.write(',${week.reactionCount[reactionKind]!}');
        }
        summary.writeln();
      }
      await File('${output.path}/weeks.csv').writeAsString(summary.toString());
      print('Weekly activity results stored in: ${output.path}/weeks.csv');
    }

    // COLLECT LABELS DATA
    final Map<String, LabelData> labels = <String, LabelData>{};
    final DateTime now = DateTime.now();
    for (final FullIssue issue in primaryIssues) {
      for (final IssueLabel label in issue.metadata.labels) {
        final LabelData data = labels.putIfAbsent(label.name, () => LabelData(label.name))
          ..all += 1
          ..issues += 1;
        if (issue.metadata.isOpen) {
          data.open += 1;
        }
        if (issue.metadata.isClosed) {
          data.closed += 1;
        }
        if (now.difference(issue.metadata.updatedAt!) < const Duration(days: 52 * 7)) {
          data.issuesUpdated52 += 1;
          if (now.difference(issue.metadata.updatedAt!) < const Duration(days: 12 * 7)) {
            data.issuesUpdated12 += 1;
          }
        }
      }
    }
    for (final FullIssue issue in primaryPRs) {
      for (final IssueLabel label in issue.metadata.labels) {
        final LabelData data = labels.putIfAbsent(label.name, () => LabelData(label.name))
          ..all += 1
          ..prs += 1;
        if (now.difference(issue.metadata.updatedAt!) < const Duration(days: 52 * 7)) {
          data.prsUpdated52 += 1;
          if (now.difference(issue.metadata.updatedAt!) < const Duration(days: 12 * 7)) {
            data.prsUpdated12 += 1;
          }
        }
      }
    }

    // PRINT LABELS DATA
    summary
      ..clear()
      ..writeln(
          'label,issues and PRs,all issues,open issues,closed issues,issues updated in last 12 weeks,issues updated in last 52 weeks,all PRs,PRs updated in last 12 weeks,PRs updated in last 52 weeks');
    for (final LabelData label in labels.values) {
      verifyStringSanity(label.name, csvSpecials);
      summary.writeln(
          '${label.name},${label.all},${label.issues},${label.open},${label.closed},${label.issuesUpdated12},${label.issuesUpdated52},${label.prs},${label.prsUpdated12},${label.prsUpdated52}');
    }
    await File('${output.path}/labels.csv').writeAsString(summary.toString());
    print('Labels stored in: ${output.path}/labels.csv');

    return 0;
  } on Abort {
    print('');
    return 2;
  } catch (e, stack) {
    // ignore: avoid_catches_without_on_clauses
    print('\nFatal error (${e.runtimeType}).');
    print('$e\n$stack');
    return 1;
  }
}

class LabelData {
  LabelData(this.name);
  final String name;
  int all = 0;
  int issues = 0;
  int open = 0;
  int closed = 0;
  int issuesUpdated12 = 0;
  int issuesUpdated52 = 0;
  int prs = 0;
  int prsUpdated12 = 0;
  int prsUpdated52 = 0;
}

class WeekActivity {
  WeekActivity(this.start, final Set<String> reactionKinds, final List<String> priorities) {
    priorityCount[null] = 0;
    for (final String priority in priorities) {
      priorityCount[priority] = 0;
    }
    for (final String reactionKind in reactionKinds) {
      reactionCount[reactionKind] = 0;
    }
  }
  final DateTime start;
  int issues = 0;
  int comments = 0;
  int closures = 0;
  int remainingIssues = 0;
  int pullRequests = 0;
  int reactions = 0;
  Map<String, int> reactionCount = <String, int>{};
  Map<String?, int> priorityCount = <String?, int>{};
  int selfClosures = 0;
  int characters = 0;

  int get total => issues + comments + closures + pullRequests + reactions;
}

class UserActivity {
  bool isMember = false;
  bool isActiveMember = false;
  List<DateTime?> issues = <DateTime?>[];
  List<DateTime?> comments = <DateTime?>[];
  List<DateTime?> closures = <DateTime?>[];
  List<DateTime?> pullRequests = <DateTime?>[];
  List<DateTime?> reactions = <DateTime?>[];
  Map<String, int> reactionCount = <String, int>{};
  Map<String?, int> priorityCount = <String?, int>{};
  int selfClosures = 0;
  int characters = 0;

  DateTime? earliest;
  DateTime? latest;

  int get total => issues.length + comments.length + closures.length + pullRequests.length + reactions.length;
  double get density => (earliest == null || latest == null)
      ? double.nan
      : total / (latest!.millisecondsSinceEpoch - earliest!.millisecondsSinceEpoch);
  double get daysActive => (earliest == null || latest == null)
      ? double.nan
      : (latest!.millisecondsSinceEpoch - earliest!.millisecondsSinceEpoch) / Duration.millisecondsPerDay;
}

class PriorityResults {
  int total = 0;
  int open = 0;
  int closed = 0;
  int openedByTeam = 0;
  int openedByNonTeam = 0;
  int openedByTeamAndClosed = 0;
  int openedByNonTeamAndClosed = 0;
  final List<Duration> timeOpen = <Duration>[];
}

Future<int> main(final List<String> arguments) async {
  print('');
  print('GitHub Repository Analysis');
  print('==========================');
  print('');
  ProcessSignal.sigint.watch().listen((final ProcessSignal signal) {
    stdout.write('\x1B[K\r');
    switch (mode) {
      case Mode.full:
        print('Skipping full update...');
        mode = Mode.abbreviated;
      case Mode.abbreviated:
        mode = Mode.aborted;
        print('Skipping to generation...');
        aborter.complete();
      case Mode.aborted:
        print('Terminating immediately!');
        exit(2);
    }
  });
  try {
    await cache.create(recursive: true);
  } on FileSystemException catch (e) {
    print('Unable to create cache in "${cache.path}": $e');
    return 1;
  }
  final Client client = _debugNetwork ? DebugHttpClient() : Client();
  late final GitHub github;
  try {
    final String token = await tokenFile.readAsString();
    github = GitHub(auth: Authentication.withToken(token), client: client);
  } on FileSystemException catch (e) {
    if (tokenFile.existsSync()) {
      print('Unable to read ${tokenFile.path}: ${e.message}');
      return 1;
    }
    print('No token file; connecting to GitHub anonymously...');
    print('');
    github = GitHub(client: client);
  }
  if (arguments.isEmpty) {
    return full(cache, github);
  }
  for (final String argument in arguments) {
    final List<String> parts = argument.split(':');
    if (parts.isNotEmpty && parts[0] == 'issue') {
      if (parts.length != 4) {
        print('Not sure what to do with "$argument" (format for issue is issue:org:repo:number).');
        exit(1);
      }
      final RepositorySlug repo = RepositorySlug(parts[1], parts[2]);
      final int? issueNumber = int.tryParse(parts[3], radix: 10);
      if (issueNumber == null) {
        print('Not sure what to do with "$argument" (fourth component is not a number).');
        exit(1);
      }
      final FullIssue issue = await FullIssue.load(
        cache: cache,
        github: github,
        repo: repo,
        issueNumber: issueNumber,
        cacheEpoch: DateTime.now().subtract(const Duration(hours: 24)),
      );
      final StringBuffer summary = StringBuffer();
      final List<int> thumbs =
          List<int>.filled(issue.reactions.last.createdAt!.difference(issue.metadata.createdAt!).inDays + 1, 0);
      for (final Reaction reaction in issue.reactions) {
        if (reaction.content == '+1') {
          final int day = reaction.createdAt!.difference(issue.metadata.createdAt!).inDays;
          thumbs[day] = thumbs[day] + 1;
        }
      }
      summary.writeln('day,thumbs,sum');
      int sum = 0;
      for (int day = 0; day < thumbs.length; day += 1) {
        sum += thumbs[day];
        summary.writeln('$day,${thumbs[day]},$sum');
      }
      await File('${output.path}/issue:${repo.owner}:${repo.name}:$issueNumber:thumbs:history.csv')
          .writeAsString(summary.toString());
    }
  }
  return 0;
}

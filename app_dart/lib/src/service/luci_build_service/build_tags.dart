// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

/// A collection of [BuildTag]s.
final class BuildTags {
  /// Creates a new set, optionally with the provided initial entries.
  factory BuildTags([Iterable<BuildTag> buildTags = const []]) {
    return BuildTags._([...buildTags]);
  }

  /// Creates a new set, parsing the providing [stringPairs] into [BuildTag]s.
  factory BuildTags.fromStringPairs(Iterable<bbv2.StringPair> stringPairs) {
    return BuildTags(stringPairs.map(BuildTag.from));
  }

  BuildTags._(this._buildTags);
  final List<BuildTag> _buildTags;

  /// Adds [buildTag].
  void add(BuildTag buildTag) {
    _buildTags.add(buildTag);
  }

  /// Returns whether at least one build tag of type [T] exists in the set.
  bool contains<T extends BuildTag>() => buildTags.whereType<T>().isNotEmpty;

  /// Returns the first build tag of type [T], or `null` if none exists.
  T? getTagOf<T extends BuildTag>() => buildTags.whereType<T>().firstOrNull;

  /// Creates a copy of the current state of the set.
  BuildTags clone() => BuildTags._([..._buildTags]);

  /// Each [BuildTag] in the set.
  Iterable<BuildTag> get buildTags => _buildTags;

  /// Returns a copy of the build tags as a list of [bbv2.StringPair]s.
  List<bbv2.StringPair> toStringPairs() {
    return buildTags.map((e) => e.toStringPair()).toList();
  }
}

/// Valid tags for [bbv2.ScheduleBuildRequest.tags].
///
/// Tags are indexed arbitrary string key-value pairs, defined by the user that
/// has scheduled the build. This class exists in order to ensure we don't
/// "fat finger" the wrong name, and know exactly what tags we are (and aren't)
/// sending, statically.
///
/// See go/buildbucket#concepts for more details.
@immutable
sealed class BuildTag {
  /// Parses and recognizes expected [BuildTag]s from their string-pair equivalent.
  factory BuildTag.from(bbv2.StringPair pair) {
    switch (pair.key) {
      case UserAgentBuildTag._keyName:
        return UserAgentBuildTag(value: pair.value);
      case BuildSetBuildTag._keyName:
        if (_parsePresubmitRef.matchAsPrefix(pair.value) case final match?) {
          final commitSha = match.group(1)!;
          return ByPresubmitCommitBuildSetBuildTag(commitSha: commitSha);
        }
        if (_parsePostsubmitRef.matchAsPrefix(pair.value) case final match?) {
          final commitSha = match.group(1)!;
          return ByPostsubmitCommitBuildSetBuildTag(commitSha: commitSha);
        }
        if (_parseCommitGittiles.matchAsPrefix(pair.value) case final match?) {
          final slugName = match.group(1)!;
          final commitSha = match.group(2)!;
          return ByCommitMirroredBuildSetBuildTag(commitSha: commitSha, slugName: slugName);
        }
      case GitHubPullRequestBuildTag._keyName:
        if (_parseGithubPullRequest.matchAsPrefix(pair.value) case final match?) {
          final slugOwner = match.group(1)!;
          final slugName = match.group(2)!;
          final prNumber = int.tryParse(match.group(3)!);
          if (prNumber == null) {
            break;
          }
          return GitHubPullRequestBuildTag(
            slugOwner: slugOwner,
            slugName: slugName,
            pullRequestNumber: prNumber,
          );
        }
      case GitHubCheckRunIdBuildTag._keyName:
        if (int.tryParse(pair.value) case final checkRunId?) {
          return GitHubCheckRunIdBuildTag(checkRunId: checkRunId);
        }
      case SchedulerJobIdBuildTag._keyName:
        if (_parseSchedulerJobId.matchAsPrefix(pair.value) case final match?) {
          final targetName = match.group(1)!;
          return SchedulerJobIdBuildTag(targetName: targetName);
        }
      case CurrentAttemptBuildTag._keyName:
        if (int.tryParse(pair.value) case final currentAttempt? when currentAttempt >= 1) {
          return CurrentAttemptBuildTag(attemptNumber: currentAttempt);
        }
      case CipdVersionBuildTag._keyName:
        if (_parseCipdVersion.matchAsPrefix(pair.value) case final match?) {
          final baseRef = match.group(1)!;
          return CipdVersionBuildTag(baseRef: baseRef);
        }
      case InMergeQueueBuildTag._keyName when pair.value == 'true':
        return InMergeQueueBuildTag();
      case TriggerTypeBuildTag._keyName:
        final matchingTag = TriggerTypeBuildTag.values.firstWhereOrNull((v) => v._value == pair.value);
        if (matchingTag != null) {
          return matchingTag;
        }
      case TriggerdByBuildTag._keyName:
        return TriggerdByBuildTag(email: pair.value);
    }
    return UnknownBuildTag(key: pair.key, value: pair.value);
  }

  static final _parsePresubmitRef = RegExp(r'sha/git/(.*)');
  static final _parsePostsubmitRef = RegExp(r'commit/git/(.*)');
  static final _parseCommitGittiles = RegExp(r'commit/gitiles/flutter.googlesource.com/mirrors/(.*)/+/(.*)');
  static final _parseGithubPullRequest = RegExp(r'https://github.com/(.*)/(.*)/pull/(.*)');
  static final _parseSchedulerJobId = RegExp(r'flutter/(.*)');
  static final _parseCipdVersion = RegExp(r'refs/heads/(.*)');

  // The class is immutable, but not every instance is const.
  // ignore: prefer_const_constructors_in_immutables
  BuildTag(this._key, this._value);

  /// The key of the build tag.
  @nonVirtual
  final String _key;

  /// The value of the build tag.
  @nonVirtual
  final String _value;

  @override
  @nonVirtual
  int get hashCode => Object.hash(_key, _value);

  @override
  @nonVirtual
  bool operator ==(Object other) {
    return other is BuildTag && _key == other._key && _value == other._value;
  }

  /// Returns the [bbv2.StringPair] representation of the tag.
  @nonVirtual
  bbv2.StringPair toStringPair() {
    return bbv2.StringPair(key: _key, value: _value);
  }

  @override
  @nonVirtual
  String toString() {
    return '$runtimeType {$_key -> $_value}';
  }
}

/// A default implementation of a [BuildTag] if not recognized by [BuildTag.from].
final class UnknownBuildTag extends BuildTag {
  @visibleForTesting
  UnknownBuildTag({required this.key, required this.value}) : super(key, value);

  /// Key name.
  final String key;

  /// Value of the string pair.
  final String value;
}

/// A user-agent, describing the client.
final class UserAgentBuildTag extends BuildTag {
  static const _keyName = 'user_agent';
  static final flutterCocoon = UserAgentBuildTag(value: 'flutter-cocoon');

  UserAgentBuildTag({required this.value}) : super(_keyName, value);

  /// Value of the user-agent.
  final String value;
}

/// Groups builds together, i.e. by a (Gerrit) CL, (GitHub) PR or (Git) commit.
sealed class BuildSetBuildTag extends BuildTag {
  static const _keyName = 'buildset';

  BuildSetBuildTag(String value) : super(_keyName, value);
}

/// A [BuildSetBuildTag] for _presubmit_ git commit SHAs.
final class ByPresubmitCommitBuildSetBuildTag extends BuildSetBuildTag {
  ByPresubmitCommitBuildSetBuildTag({required this.commitSha}) : super('sha/git/$commitSha');

  /// Which presubmit commit SHA this buildset is connected to.
  final String commitSha;
}

/// A [BuildSetBuildTag] for _postsubmit_ git commit SHAs.
final class ByPostsubmitCommitBuildSetBuildTag extends BuildSetBuildTag {
  ByPostsubmitCommitBuildSetBuildTag({required this.commitSha}) : super('commit/git/$commitSha');

  /// Which postsubmit commit SHA this buildset is connected to.
  final String commitSha;
}

/// A [BuildSetBuildTag] for git commit SHAs viewable through `gittiles`.
///
/// This is used for `flutter.googlesource.com/mirrors`.
final class ByCommitMirroredBuildSetBuildTag extends BuildSetBuildTag {
  ByCommitMirroredBuildSetBuildTag({
    required this.commitSha,
    required this.slugName,
  }) : super('commit/gitiles/flutter.googlesource.com/mirrors/$slugName/+/$commitSha') {
    // If this is wrong in production it's probably not worth crashing.
    assert(
      _validMirrors.contains(slugName),
      'Unsupported flutter.googlesource.com/mirrors repository: $slugName.',
    );
  }

  /// Will need to be updated if https://flutter.googlesource.com/mirrors is updated.
  static const _validMirrors = {
    'cocoon',
    'engine',
    'flaux',
    'flutter',
    'packages',
    'plugins',
  };

  /// Which commit SHA this buildset is connected to.
  final String commitSha;

  /// Which repository in `flutter.googlesource.com/mirrors` this commit is for.
  final String slugName;
}

/// A link back to the GitHub PR for this build.
final class GitHubPullRequestBuildTag extends BuildTag {
  static const _keyName = 'github_link';

  GitHubPullRequestBuildTag({
    required this.slugOwner,
    required this.slugName,
    required this.pullRequestNumber,
  }) : super(_keyName, 'https://github.com/$slugOwner/$slugName/pull/$pullRequestNumber');

  /// Which repository in `https://github.com/{owner}`.
  final String slugOwner;

  /// Which repository in `https://github.com/{owner}/{slugName}`.
  final String slugName;

  /// Pull request number.
  final int pullRequestNumber;
}

/// A link back to the GitHub checkRun for this build.
final class GitHubCheckRunIdBuildTag extends BuildTag {
  static const _keyName = 'github_checkrun';
  GitHubCheckRunIdBuildTag({required this.checkRunId}) : super(_keyName, '$checkRunId');

  /// ID of the checkRun.
  final int checkRunId;
}

/// A build tag that specifies the ID of the scheduling job.
///
/// For Flutter, this is always `flutter/{Build Target}`.
final class SchedulerJobIdBuildTag extends BuildTag {
  static const _keyName = 'scheduler_job_id';

  SchedulerJobIdBuildTag({
    required this.targetName,
  }) : super(_keyName, 'flutter/$targetName');

  /// The name of the target defined in `.ci.yaml`.
  final String targetName;
}

/// A build tag that specifies what [attemptNumber] this build is.
final class CurrentAttemptBuildTag extends BuildTag {
  static const _keyName = 'current_attempt';

  CurrentAttemptBuildTag({required this.attemptNumber}) : super(_keyName, '$attemptNumber') {
    if (attemptNumber < 1) {
      throw RangeError.value(attemptNumber, 'attemptNumber', 'Must be at least 1');
    }
  }

  /// Which attempt at building this is (starting at 1, and incrementing for each reschedule).
  final int attemptNumber;
}

/// A version of the executable package to fetch, default is refs/heads/main.
///
/// See https://chromium.googlesource.com/infra/luci/luci-go/+/HEAD/lucicfg/doc/README.md#luci.executable.
final class CipdVersionBuildTag extends BuildTag {
  static const _keyName = 'cipd_version';
  static final main = CipdVersionBuildTag(baseRef: 'main');

  CipdVersionBuildTag({required this.baseRef}) : super(_keyName, 'refs/heads/$baseRef');

  /// Which baseRef to use for CIPD downloads.
  ///
  /// Defaults to `main`.
  final String baseRef;
}

/// Specifies that this build is from the merge queue.
final class InMergeQueueBuildTag extends BuildTag {
  static const _keyName = 'in_merge_queue';

  InMergeQueueBuildTag() : super(_keyName, 'true');
}

/// How a build is triggered.
enum TriggerTypeBuildTag implements BuildTag {
  autoRetry('auto_retry'),
  checkRunManualRetry('check_run_manual_retry'),
  manualRetry('manual_retry');

  const TriggerTypeBuildTag(this._value);

  @override
  String get _key => _keyName;
  static const _keyName = 'trigger_type';

  @override
  final String _value;

  @override
  bbv2.StringPair toStringPair() {
    return bbv2.StringPair(key: _key, value: _value);
  }
}

/// Who triggered a rerun.
final class TriggerdByBuildTag extends BuildTag {
  static const _keyName = 'triggered_by';

  TriggerdByBuildTag({required this.email}) : super(_keyName, email);

  /// The email address of the triggering user.
  final String email;
}

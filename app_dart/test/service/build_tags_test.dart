// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:cocoon_service/src/service/luci_build_service/build_tags.dart';
import 'package:cocoon_service/src/service/luci_build_service/cipd_version.dart';
import 'package:test/test.dart';

void main() {
  group('BuildTags', () {
    test('creates an empty set', () {
      final set = BuildTags();
      expect(set.buildTags, isEmpty);
    });

    test('creates an initial set', () {
      final set = BuildTags([
        TriggerTypeBuildTag.autoRetry,
        GitHubCheckRunIdBuildTag(checkRunId: 1234),
      ]);
      expect(
        set.buildTags,
        unorderedEquals([
          TriggerTypeBuildTag.autoRetry,
          GitHubCheckRunIdBuildTag(checkRunId: 1234),
        ]),
      );
    });

    test('adds a new tag', () {
      final set = BuildTags([TriggerTypeBuildTag.autoRetry]);
      set.add(GitHubCheckRunIdBuildTag(checkRunId: 1234));
      expect(
        set.buildTags,
        unorderedEquals([
          TriggerTypeBuildTag.autoRetry,
          GitHubCheckRunIdBuildTag(checkRunId: 1234),
        ]),
      );
    });

    test('adds a new tag does not replace an existing one', () {
      final set = BuildTags([TriggerTypeBuildTag.autoRetry]);
      set.add(TriggerTypeBuildTag.manualRetry);
      expect(
        set.buildTags,
        unorderedEquals([
          TriggerTypeBuildTag.autoRetry,
          TriggerTypeBuildTag.manualRetry,
        ]),
      );
    });

    test('clones a set', () {
      final a = BuildTags([TriggerTypeBuildTag.autoRetry]);
      final b = a.clone();

      a.add(TriggerTypeBuildTag.checkRunManualRetry);
      b.add(TriggerTypeBuildTag.manualRetry);

      expect(a.buildTags, unorderedEquals([TriggerTypeBuildTag.autoRetry, TriggerTypeBuildTag.checkRunManualRetry]));
      expect(b.buildTags, unorderedEquals([TriggerTypeBuildTag.autoRetry, TriggerTypeBuildTag.manualRetry]));
    });

    test('creates string pairs', () {
      final set = BuildTags([TriggerTypeBuildTag.autoRetry]);
      expect(
        set.toStringPairs(),
        unorderedEquals([
          bbv2.StringPair(key: 'trigger_type', value: 'auto_retry'),
        ]),
      );
    });
  });

  group('UserAgentBuildTag', () {
    test('can be produced', () {
      final userAgent = UserAgentBuildTag(value: 'flutter-foo');
      expect(
        userAgent.toStringPair(),
        bbv2.StringPair(
          key: 'user_agent',
          value: 'flutter-foo',
        ),
      );
    });

    test('the default is flutter-cocoon', () {
      expect(
        UserAgentBuildTag.flutterCocoon.toStringPair(),
        bbv2.StringPair(
          key: 'user_agent',
          value: 'flutter-cocoon',
        ),
      );
    });

    test('can be parsed', () {
      final tag = BuildTag.from(bbv2.StringPair(key: 'user_agent', value: 'flutter-foo'));
      expect(tag, UserAgentBuildTag(value: 'flutter-foo'));
    });
  });

  group('BuildSetBuildTag', () {
    group('ByPresubmitCommitBuildSetBuildTag', () {
      test('can be produced', () {
        expect(
          ByPresubmitCommitBuildSetBuildTag(commitSha: 'abc123').toStringPair(),
          bbv2.StringPair(key: 'buildset', value: 'sha/git/abc123'),
        );
      });

      test('can be parsed', () {
        final tag = BuildTag.from(bbv2.StringPair(key: 'buildset', value: 'sha/git/abc123'));
        expect(tag, ByPresubmitCommitBuildSetBuildTag(commitSha: 'abc123'));
      });

      test('fallsback to UnknownBuildTag if parsing fails', () {
        final tag = BuildTag.from(bbv2.StringPair(key: 'buildset', value: 'sha/git\\/malformed'));
        expect(tag, UnknownBuildTag(key: 'buildset', value: 'sha/git\\/malformed'));
      });
    });

    group('ByPostsubmitCommitBuildSetBuildTag', () {
      test('can be produced', () {
        expect(
          ByPostsubmitCommitBuildSetBuildTag(commitSha: 'abc123').toStringPair(),
          bbv2.StringPair(key: 'buildset', value: 'commit/git/abc123'),
        );
      });

      test('can be parsed', () {
        final tag = BuildTag.from(bbv2.StringPair(key: 'buildset', value: 'commit/git/abc123'));
        expect(tag, ByPostsubmitCommitBuildSetBuildTag(commitSha: 'abc123'));
      });

      test('fallsback to UnknownBuildTag if parsing fails', () {
        final tag = BuildTag.from(bbv2.StringPair(key: 'buildset', value: 'commit/git\\/malformed'));
        expect(tag, UnknownBuildTag(key: 'buildset', value: 'commit/git\\/malformed'));
      });
    });

    group('ByCommitMirroredBuildSetBuildTag', () {
      test('can be produced', () {
        expect(
          ByCommitMirroredBuildSetBuildTag(commitSha: 'abc123', slugName: 'flutter').toStringPair(),
          bbv2.StringPair(key: 'buildset', value: 'commit/gitiles/flutter.googlesource.com/mirrors/flutter/+/abc123'),
        );
      });

      test('can be parsed', () {
        final tag = BuildTag.from(
          bbv2.StringPair(
            key: 'buildset',
            value: 'commit/gitiles/flutter.googlesource.com/mirrors/flutter/+/abc123',
          ),
        );
        expect(tag, ByCommitMirroredBuildSetBuildTag(commitSha: 'abc123', slugName: 'flutter'));
      });

      test('fallsback to UnknownBuildTag if parsing fails', () {
        final tag = BuildTag.from(
          bbv2.StringPair(
            key: 'buildset',
            value: 'commit/gitiles/MALFORMED.googlesource.com/mirrors/flutter/+/abc123',
          ),
        );
        expect(
          tag,
          UnknownBuildTag(key: 'buildset', value: 'commit/gitiles/MALFORMED.googlesource.com/mirrors/flutter/+/abc123'),
        );
      });
    });
  });

  group('GitHubPullRequestBuildTag', () {
    test('can be produced', () {
      expect(
        GitHubPullRequestBuildTag(
          slugOwner: 'owner',
          slugName: 'repo',
          pullRequestNumber: 1234,
        ).toStringPair(),
        bbv2.StringPair(
          key: 'github_link',
          value: 'https://github.com/owner/repo/pull/1234',
        ),
      );
    });

    test('can be parsed', () {
      final tag = BuildTag.from(
        bbv2.StringPair(
          key: 'github_link',
          value: 'https://github.com/owner/repo/pull/1234',
        ),
      );
      expect(
        tag,
        GitHubPullRequestBuildTag(
          slugOwner: 'owner',
          slugName: 'repo',
          pullRequestNumber: 1234,
        ),
      );
    });

    test('fallsback to UnknownBuildTag if parsing fails', () {
      final tag = BuildTag.from(
        bbv2.StringPair(
          key: 'github_link',
          value: 'https:/\\/malformed/1234',
        ),
      );
      expect(
        tag,
        UnknownBuildTag(
          key: 'github_link',
          value: 'https:/\\/malformed/1234',
        ),
      );
    });
  });

  group('GitHubCheckRunIdBuildTag', () {
    test('can be produced', () {
      expect(
        GitHubCheckRunIdBuildTag(checkRunId: 1234).toStringPair(),
        bbv2.StringPair(
          key: 'github_checkrun',
          value: '1234',
        ),
      );
    });

    test('can be parsed', () {
      final tag = BuildTag.from(
        bbv2.StringPair(
          key: 'github_checkrun',
          value: '1234',
        ),
      );
      expect(
        tag,
        GitHubCheckRunIdBuildTag(checkRunId: 1234),
      );
    });

    test('fallsback to UnknownBuildTag if parsing fails', () {
      final tag = BuildTag.from(
        bbv2.StringPair(
          key: 'github_checkrun',
          value: 'a-notANumber',
        ),
      );
      expect(
        tag,
        UnknownBuildTag(
          key: 'github_checkrun',
          value: 'a-notANumber',
        ),
      );
    });
  });

  group('SchedulerJobIdBuildTag', () {
    test('can be produced', () {
      expect(
        SchedulerJobIdBuildTag(targetName: 'Linux_foo').toStringPair(),
        bbv2.StringPair(
          key: 'scheduler_job_id',
          value: 'flutter/Linux_foo',
        ),
      );
    });

    test('can be parsed', () {
      final tag = BuildTag.from(
        bbv2.StringPair(
          key: 'scheduler_job_id',
          value: 'flutter/Linux_foo',
        ),
      );
      expect(
        tag,
        SchedulerJobIdBuildTag(targetName: 'Linux_foo'),
      );
    });

    test('fallsback to UnknownBuildTag if parsing fails', () {
      final tag = BuildTag.from(
        bbv2.StringPair(
          key: 'scheduler_job_id',
          value: 'malformed\\Bar',
        ),
      );
      expect(
        tag,
        UnknownBuildTag(
          key: 'scheduler_job_id',
          value: 'malformed\\Bar',
        ),
      );
    });
  });

  group('CurrentAttemptBuildTag', () {
    test('can be produced', () {
      expect(
        CurrentAttemptBuildTag(attemptNumber: 1).toStringPair(),
        bbv2.StringPair(
          key: 'current_attempt',
          value: '1',
        ),
      );
    });

    test('refuses a non-positive number', () {
      expect(() => CurrentAttemptBuildTag(attemptNumber: 0), throwsRangeError);
      expect(() => CurrentAttemptBuildTag(attemptNumber: -1), throwsRangeError);
      expect(() => CurrentAttemptBuildTag(attemptNumber: 1), returnsNormally);
      expect(() => CurrentAttemptBuildTag(attemptNumber: 2), returnsNormally);
    });

    test('can be parsed', () {
      final tag = BuildTag.from(
        bbv2.StringPair(
          key: 'current_attempt',
          value: '1',
        ),
      );
      expect(
        tag,
        CurrentAttemptBuildTag(attemptNumber: 1),
      );
    });

    test('fallsback to UnknownBuildTag if parsing fails', () {
      final tag = BuildTag.from(
        bbv2.StringPair(
          key: 'current_attempt',
          value: 'notANumber',
        ),
      );
      expect(
        tag,
        UnknownBuildTag(
          key: 'current_attempt',
          value: 'notANumber',
        ),
      );
    });

    test('fallsback to UnknownBuildTag if unexpected number', () {
      final tag = BuildTag.from(
        bbv2.StringPair(
          key: 'current_attempt',
          value: '0',
        ),
      );
      expect(
        tag,
        UnknownBuildTag(
          key: 'current_attempt',
          value: '0',
        ),
      );
    });
  });

  group('CipdVersionBuildTag', () {
    test('can be produced', () {
      expect(
        CipdVersionBuildTag(const CipdVersion(branch: 'foo-bar')).toStringPair(),
        bbv2.StringPair(
          key: 'cipd_version',
          value: 'refs/heads/foo-bar',
        ),
      );
    });

    test('can be parsed', () {
      final tag = BuildTag.from(
        bbv2.StringPair(
          key: 'cipd_version',
          value: 'refs/heads/foo-bar',
        ),
      );
      expect(
        tag,
        CipdVersionBuildTag(const CipdVersion(branch: 'foo-bar')),
      );
    });

    test('fallsback to UnknownBuildTag if parsing fails', () {
      final tag = BuildTag.from(
        bbv2.StringPair(
          key: 'cipd_version',
          value: 'refs\\malformed/foo-bar',
        ),
      );
      expect(
        tag,
        UnknownBuildTag(
          key: 'cipd_version',
          value: 'refs\\malformed/foo-bar',
        ),
      );
    });
  });

  group('InMergeQueueBuildTag', () {
    test('can be produced', () {
      expect(
        InMergeQueueBuildTag().toStringPair(),
        bbv2.StringPair(key: 'in_merge_queue', value: 'true'),
      );
    });

    test('can be parsed', () {
      final tag = BuildTag.from(bbv2.StringPair(key: 'in_merge_queue', value: 'true'));
      expect(
        tag,
        InMergeQueueBuildTag(),
      );
    });

    test('fallsback to UnknownBuildTag if parsing fails', () {
      final tag = BuildTag.from(
        bbv2.StringPair(
          key: 'in_merge_queue',
          value: 'false',
        ),
      );
      expect(
        tag,
        UnknownBuildTag(
          key: 'in_merge_queue',
          value: 'false',
        ),
      );
    });
  });

  group('TriggerTypeBuildTag', () {
    test('can be produced', () {
      expect(
        TriggerTypeBuildTag.autoRetry.toStringPair(),
        bbv2.StringPair(key: 'trigger_type', value: 'auto_retry'),
      );

      expect(
        TriggerTypeBuildTag.checkRunManualRetry.toStringPair(),
        bbv2.StringPair(key: 'trigger_type', value: 'check_run_manual_retry'),
      );

      expect(
        TriggerTypeBuildTag.manualRetry.toStringPair(),
        bbv2.StringPair(key: 'trigger_type', value: 'manual_retry'),
      );
    });

    test('can be parsed', () {
      expect(
        BuildTag.from(bbv2.StringPair(key: 'trigger_type', value: 'auto_retry')),
        TriggerTypeBuildTag.autoRetry,
      );

      expect(
        BuildTag.from(bbv2.StringPair(key: 'trigger_type', value: 'check_run_manual_retry')),
        TriggerTypeBuildTag.checkRunManualRetry,
      );

      expect(
        BuildTag.from(bbv2.StringPair(key: 'trigger_type', value: 'manual_retry')),
        TriggerTypeBuildTag.manualRetry,
      );
    });

    test('fallsback to UnknownBuildTag if parsing fails', () {
      expect(
        BuildTag.from(bbv2.StringPair(key: 'trigger_type', value: 'not_a_thing')),
        UnknownBuildTag(key: 'trigger_type', value: 'not_a_thing'),
      );
    });
  });

  group('TriggerdByBuildTag', () {
    test('can be produced', () {
      expect(
        TriggerdByBuildTag(email: 'foo@bar.com').toStringPair(),
        bbv2.StringPair(key: 'triggered_by', value: 'foo@bar.com'),
      );
    });

    test('can be parsed', () {
      expect(
        BuildTag.from(bbv2.StringPair(key: 'triggered_by', value: 'foo@bar.com')),
        TriggerdByBuildTag(email: 'foo@bar.com'),
      );
    });
  });
}

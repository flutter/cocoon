// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/protos.dart' as pb;
import 'package:cocoon_service/src/model/ci_yaml/ci_yaml.dart';
import 'package:cocoon_service/src/model/ci_yaml/target.dart';
import 'package:cocoon_service/src/service/config.dart';
import 'package:test/test.dart';

import '../../src/service/fake_scheduler.dart';

void main() {
  useTestLoggerPerTest();

  group('enabledBranchesMatchesCurrentBranch', () {
    final tests = <EnabledBranchesRegexTest>[
      EnabledBranchesRegexTest('matches main', 'main', <String>['main']),
      EnabledBranchesRegexTest(
        'matches candidate branch',
        'flutter-2.4-candidate.3',
        <String>['flutter-\\d+\\.\\d+-candidate\\.\\d+'],
      ),
      EnabledBranchesRegexTest(
        'matches main when not first pattern',
        'main',
        <String>['dev', 'main'],
      ),
      EnabledBranchesRegexTest(
        'does not do partial matches',
        'super-main',
        <String>['main'],
        false,
      ),
    ];

    for (var regexTest in tests) {
      test(regexTest.name, () {
        expect(
          CiYaml.enabledBranchesMatchesCurrentBranch(
            regexTest.enabledBranches,
            regexTest.branch,
          ),
          regexTest.expectation,
        );
      });
    }
  });

  group('Validate pinned version operation.', () {
    void validatePinnedVersion(String input) {
      test('$input -> returns normally', () {
        DependencyValidator.hasVersion(dependencyJsonString: input);
      });
    }

    validatePinnedVersion(
      '[{"dependency": "chrome_and_driver", "version": "version:96.2"}]',
    );
    validatePinnedVersion('[{"dependency": "open_jdk", "version": "11"}]');
    validatePinnedVersion(
      '[{"dependency": "android_sdk", "version": "version:31v8"}]',
    );
    validatePinnedVersion(
      '[{"dependency": "goldctl", "version": "git_revision:3a77d0b12c697a840ca0c7705208e8622dc94603"}]',
    );
  });

  group('Validate un-pinned version operation.', () {
    void validateUnPinnedVersion(String input) {
      test('$input -> returns normally', () {
        expect(
          () => DependencyValidator.hasVersion(dependencyJsonString: input),
          throwsException,
        );
      });
    }

    validateUnPinnedVersion('[{"dependency": "some_sdk", "version": ""}]');
    validateUnPinnedVersion('[{"dependency": "another_sdk"}]');
    validateUnPinnedVersion(
      '[{"dependency": "yet_another_sdk", "version": "latest"}]',
    );
  });

  group('initialTargets', () {
    test('targets without deps', () {
      final ciYaml = multiTargetFusionConfig;
      final initialTargets = ciYaml.getInitialTargets(
        ciYaml.postsubmitTargets(),
      );
      final initialTargetNames =
          initialTargets.map((Target target) => target.value.name).toList();
      expect(
        initialTargetNames,
        containsAll(<String>['Linux A', 'Mac A', 'Windows A']),
      );
    });

    test('filter bringup targets on release branches', () {
      final ciYaml = CiYamlSet(
        slug: Config.flutterSlug,
        branch: Config.defaultBranch(Config.flutterSlug),
        yamls: {
          CiType.any: pb.SchedulerConfig(
            enabledBranches: <String>[Config.defaultBranch(Config.flutterSlug)],
            targets: <pb.Target>[
              pb.Target(name: 'Linux A'),
              pb.Target(
                name: 'Mac A', // Should be ignored on release branches
                bringup: true,
              ),
            ],
          ),
        },
      );
      final initialTargets = ciYaml.getInitialTargets(
        ciYaml.postsubmitTargets(),
      );
      final initialTargetNames =
          initialTargets.map((Target target) => target.value.name).toList();
      expect(initialTargetNames, containsAll(<String>['Linux A']));
    });

    group('validations and filters.', () {
      final totCIYaml = CiYaml(
        type: CiType.any,
        slug: Config.flutterSlug,
        branch: Config.defaultBranch(Config.flutterSlug),
        config: pb.SchedulerConfig(
          enabledBranches: <String>[Config.defaultBranch(Config.flutterSlug)],
          targets: <pb.Target>[
            pb.Target(name: 'Linux A'),
            pb.Target(
              name: 'Mac A', // Should be ignored on release branches
              bringup: true,
            ),
          ],
        ),
      );
      final ciYaml = CiYaml(
        type: CiType.any,
        slug: Config.flutterSlug,
        branch: 'flutter-2.4-candidate.3',
        config: pb.SchedulerConfig(
          enabledBranches: <String>['flutter-2.4-candidate.3'],
          targets: <pb.Target>[
            pb.Target(name: 'Linux A'),
            pb.Target(name: 'Linux B'),
            pb.Target(
              name: 'Mac A', // Should be ignored on release branches
              bringup: true,
            ),
          ],
        ),
        totConfig: totCIYaml,
      );

      test('filter targets removed from presubmit', () {
        final initialTargets = ciYaml.presubmitTargets;
        final initialTargetNames =
            initialTargets.map((Target target) => target.value.name).toList();
        expect(initialTargetNames, containsAll(<String>['Linux A']));
      });

      test('handles github merge queue branch', () {
        final ciYaml = CiYaml(
          type: CiType.any,
          slug: Config.flutterSlug,
          branch:
              'gh-readonly-queue/master/pr-160481-1398dc7eecb696d302e4edb19ad79901e615ed56',
          config: pb.SchedulerConfig(
            enabledBranches: <String>['master'],
            targets: <pb.Target>[
              pb.Target(name: 'Linux A'),
              pb.Target(name: 'Linux B'),
              pb.Target(
                name: 'Mac A', // Should be ignored on release branches
                bringup: true,
              ),
            ],
          ),
          totConfig: totCIYaml,
        );

        final initialTargetNames =
            ciYaml.presubmitTargets
                .map((Target target) => target.value.name)
                .toList();
        expect(initialTargetNames, containsAll(<String>['Linux A']));
      });

      test('filter targets removed from postsubmit', () {
        final initialTargets = ciYaml.postsubmitTargets;
        final initialTargetNames =
            initialTargets.map((Target target) => target.value.name).toList();
        expect(initialTargetNames, containsAll(<String>['Linux A']));
      });

      test('Get backfill targets from postsubmit', () {
        final ciYaml = exampleBackfillFusionConfig;
        final backfillTargets = ciYaml.backfillTargets();
        final backfillTargetNames =
            backfillTargets.map((Target target) => target.value.name).toList();
        expect(backfillTargetNames, containsAll(<String>['Linux A', 'Mac A']));
      });

      test('filter release_build targets from release candidate branches', () {
        final releaseYaml = CiYaml(
          type: CiType.any,
          slug: Config.flutterSlug,
          branch: 'flutter-2.4-candidate.3',
          config: pb.SchedulerConfig(
            enabledBranches: <String>['flutter-2.4-candidate.3'],
            targets: <pb.Target>[
              pb.Target(
                name: 'Linux A',
                properties: <String, String>{'release_build': 'true'},
              ),
              pb.Target(name: 'Linux B'),
              pb.Target(
                name: 'Mac A', // Should be ignored on release branches
                bringup: true,
              ),
            ],
          ),
          totConfig: totCIYaml,
        );
        final initialTargets = releaseYaml.postsubmitTargets;
        final initialTargetNames =
            initialTargets.map((Target target) => target.value.name).toList();
        expect(initialTargetNames, isEmpty);
      });

      test('release_build targets for master are filtered out', () {
        final releaseYaml = CiYaml(
          type: CiType.any,
          slug: Config.flutterSlug,
          branch: 'master',
          config: pb.SchedulerConfig(
            targets: <pb.Target>[
              pb.Target(
                name: 'Linux A',
                properties: <String, String>{'release_build': 'true'},
              ),
              pb.Target(name: 'Linux B'),
              pb.Target(
                name: 'Mac A', // Should be ignored on release branches
                bringup: true,
              ),
            ],
          ),
          totConfig: totCIYaml,
        );
        final initialTargets = releaseYaml.postsubmitTargets;
        final initialTargetNames =
            initialTargets.map((target) => target.value.name).toList();
        expect(initialTargetNames, containsAll(<String>['Mac A']));
      });

      test(
        'release_build and bringup targets are correctly filtered for postsubmit in fusion mode',
        () {
          final releaseYaml = CiYaml(
            type: CiType.any,
            slug: Config.flutterSlug,
            branch: 'main',
            config: pb.SchedulerConfig(
              targets: <pb.Target>[
                pb.Target(
                  name: 'Linux A',
                  properties: <String, String>{'release_build': 'true'},
                ),
                pb.Target(name: 'Linux B'),
                pb.Target(
                  name: 'Mac A', // Should be ignored on release branches
                  bringup: true,
                ),
              ],
            ),
          );
          final initialTargets = releaseYaml.postsubmitTargets;
          final initialTargetNames =
              initialTargets.map((Target target) => target.value.name).toList();
          expect(initialTargetNames, <String>[
            // This is a non-release target and therefore must run in post-submit in fusion mode.
            'Linux B',
            // This is a bringup target and therefore must run in post-submit on a non-release branch.
            'Mac A',
          ]);
        },
      );

      test('validates yaml config', () {
        expect(
          () => CiYaml(
            type: CiType.any,
            slug: Config.flutterSlug,
            branch: Config.defaultBranch(Config.flutterSlug),
            config: pb.SchedulerConfig(
              enabledBranches: <String>[
                Config.defaultBranch(Config.flutterSlug),
              ],
              targets: <pb.Target>[
                pb.Target(name: 'Linux A'),
                pb.Target(name: 'Linux B'),
              ],
            ),
            totConfig: totCIYaml,
            validate: true,
          ),
          throwsA(isA<FormatException>()),
        );
      });
    });

    group('Presubmit validation', () {
      final totCIYaml = CiYaml(
        type: CiType.any,
        slug: Config.flutterSlug,
        branch: Config.defaultBranch(Config.flutterSlug),
        config: pb.SchedulerConfig(
          enabledBranches: <String>[Config.defaultBranch(Config.flutterSlug)],
          targets: <pb.Target>[
            pb.Target(name: 'Linux A', presubmit: false),
            pb.Target(
              name: 'Mac A', // Should be ignored on release branches
              bringup: true,
            ),
          ],
        ),
      );
      final ciYaml = CiYaml(
        type: CiType.any,
        slug: Config.flutterSlug,
        branch: 'flutter-2.4-candidate.3',
        config: pb.SchedulerConfig(
          targets: <pb.Target>[
            pb.Target(name: 'Linux A', presubmit: true),
            pb.Target(name: 'Linux B'),
            pb.Target(
              name: 'Mac A', // Should be ignored on release branches
              bringup: true,
            ),
          ],
        ),
        totConfig: totCIYaml,
      );

      test(
        'presubmit true target is scheduled though TOT is with presubmit false',
        () {
          final initialTargets = ciYaml.presubmitTargets;
          final initialTargetNames =
              initialTargets.map((Target target) => target.value.name).toList();
          expect(initialTargetNames, containsAll(<String>['Linux A']));
        },
      );
    });
  });

  group('flakiness_threshold', () {
    test('is set', () {
      final ciYaml = exampleFlakyFusionConfig;
      final flaky1 = ciYaml.getFirstPostsubmitTarget('Flaky 1');
      expect(flaky1, isNotNull);
      expect(flaky1?.flakinessThreshold, 0.04);
    });

    test('is missing', () {
      final ciYaml = exampleFlakyFusionConfig;
      final flaky1 = ciYaml.getFirstPostsubmitTarget('Flaky Skip');
      expect(flaky1, isNotNull);
      expect(flaky1?.flakinessThreshold, isNull);
    });
  });
}

/// Wrapper class for table driven design of [CiYaml.enabledBranchesMatchesCurrentBranch].
class EnabledBranchesRegexTest {
  EnabledBranchesRegexTest(
    this.name,
    this.branch,
    this.enabledBranches, [
    this.expectation = true,
  ]);

  final String branch;
  final List<String> enabledBranches;
  final String name;
  final bool expectation;
}

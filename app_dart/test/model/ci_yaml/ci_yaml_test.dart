// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/model/ci_yaml/ci_yaml.dart';
import 'package:cocoon_service/src/model/ci_yaml/target.dart';
import 'package:cocoon_service/protos.dart' as pb;
import 'package:cocoon_service/src/service/config.dart';
import 'package:test/test.dart';

import '../../src/service/fake_scheduler_v2.dart';

void main() {
  group('enabledBranchesMatchesCurrentBranch', () {
    final List<EnabledBranchesRegexTest> tests = <EnabledBranchesRegexTest>[
      EnabledBranchesRegexTest('matches main', 'main', <String>['main']),
      EnabledBranchesRegexTest(
        'matches candidate branch',
        'flutter-2.4-candidate.3',
        <String>['flutter-\\d+\\.\\d+-candidate\\.\\d+'],
      ),
      EnabledBranchesRegexTest('matches main when not first pattern', 'main', <String>['dev', 'main']),
      EnabledBranchesRegexTest('does not do partial matches', 'super-main', <String>['main'], false),
    ];

    for (EnabledBranchesRegexTest regexTest in tests) {
      test(regexTest.name, () {
        expect(
          CiYaml.enabledBranchesMatchesCurrentBranch(regexTest.enabledBranches, regexTest.branch),
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

    validatePinnedVersion('[{"dependency": "chrome_and_driver", "version": "version:96.2"}]');
    validatePinnedVersion('[{"dependency": "open_jdk", "version": "11"}]');
    validatePinnedVersion('[{"dependency": "android_sdk", "version": "version:31v8"}]');
    validatePinnedVersion(
      '[{"dependency": "goldctl", "version": "git_revision:3a77d0b12c697a840ca0c7705208e8622dc94603"}]',
    );
  });

  group('Validate un-pinned version operation.', () {
    void validateUnPinnedVersion(String input) {
      test('$input -> returns normally', () {
        expect(() => DependencyValidator.hasVersion(dependencyJsonString: input), throwsException);
      });
    }

    validateUnPinnedVersion('[{"dependency": "some_sdk", "version": ""}]');
    validateUnPinnedVersion('[{"dependency": "another_sdk"}]');
    validateUnPinnedVersion('[{"dependency": "yet_another_sdk", "version": "latest"}]');
  });

  group('initialTargets', () {
    test('targets without deps', () {
      final CiYaml ciYaml = exampleConfig;
      final List<Target> initialTargets = ciYaml.getInitialTargets(ciYaml.postsubmitTargets);
      final List<String> initialTargetNames = initialTargets.map((Target target) => target.value.name).toList();
      expect(
        initialTargetNames,
        containsAll(
          <String>[
            'Linux A',
            'Mac A',
            'Windows A',
          ],
        ),
      );
    });

    test('filter bringup targets on release branches', () {
      final CiYaml ciYaml = CiYaml(
        slug: Config.flutterSlug,
        branch: Config.defaultBranch(Config.flutterSlug),
        config: pb.SchedulerConfig(
          enabledBranches: <String>[
            Config.defaultBranch(Config.flutterSlug),
          ],
          targets: <pb.Target>[
            pb.Target(
              name: 'Linux A',
            ),
            pb.Target(
              name: 'Mac A', // Should be ignored on release branches
              bringup: true,
            ),
          ],
        ),
      );
      final List<Target> initialTargets = ciYaml.getInitialTargets(ciYaml.postsubmitTargets);
      final List<String> initialTargetNames = initialTargets.map((Target target) => target.value.name).toList();
      expect(
        initialTargetNames,
        containsAll(
          <String>[
            'Linux A',
          ],
        ),
      );
    });

    group('validations and filters.', () {
      final CiYaml totCIYaml = CiYaml(
        slug: Config.flutterSlug,
        branch: Config.defaultBranch(Config.flutterSlug),
        config: pb.SchedulerConfig(
          enabledBranches: <String>[
            Config.defaultBranch(Config.flutterSlug),
          ],
          targets: <pb.Target>[
            pb.Target(
              name: 'Linux A',
            ),
            pb.Target(
              name: 'Mac A', // Should be ignored on release branches
              bringup: true,
            ),
          ],
        ),
      );
      final CiYaml ciYaml = CiYaml(
        slug: Config.flutterSlug,
        branch: 'flutter-2.4-candidate.3',
        config: pb.SchedulerConfig(
          enabledBranches: <String>[
            'flutter-2.4-candidate.3',
          ],
          targets: <pb.Target>[
            pb.Target(
              name: 'Linux A',
            ),
            pb.Target(
              name: 'Linux B',
            ),
            pb.Target(
              name: 'Mac A', // Should be ignored on release branches
              bringup: true,
            ),
          ],
        ),
        totConfig: totCIYaml,
      );

      test('filter targets removed from presubmit', () {
        final List<Target> initialTargets = ciYaml.presubmitTargets;
        final List<String> initialTargetNames = initialTargets.map((Target target) => target.value.name).toList();
        expect(
          initialTargetNames,
          containsAll(
            <String>[
              'Linux A',
            ],
          ),
        );
      });

      test('filter targets removed from postsubmit', () {
        final List<Target> initialTargets = ciYaml.postsubmitTargets;
        final List<String> initialTargetNames = initialTargets.map((Target target) => target.value.name).toList();
        expect(
          initialTargetNames,
          containsAll(
            <String>[
              'Linux A',
            ],
          ),
        );
      });

      test('Get backfill targets from postsubmit', () {
        final CiYaml ciYaml = exampleBackfillConfig;
        final List<Target> backfillTargets = ciYaml.backfillTargets;
        final List<String> backfillTargetNames = backfillTargets.map((Target target) => target.value.name).toList();
        expect(
          backfillTargetNames,
          containsAll(
            <String>[
              'Linux A',
              'Mac A',
            ],
          ),
        );
      });

      test('filter release_build targets from release candidate branches', () {
        final CiYaml releaseYaml = CiYaml(
          slug: Config.flutterSlug,
          branch: 'flutter-2.4-candidate.3',
          config: pb.SchedulerConfig(
            enabledBranches: <String>[
              'flutter-2.4-candidate.3',
            ],
            targets: <pb.Target>[
              pb.Target(
                name: 'Linux A',
                properties: <String, String>{'release_build': 'true'},
              ),
              pb.Target(
                name: 'Linux B',
              ),
              pb.Target(
                name: 'Mac A', // Should be ignored on release branches
                bringup: true,
              ),
            ],
          ),
          totConfig: totCIYaml,
        );
        final List<Target> initialTargets = releaseYaml.postsubmitTargets;
        final List<String> initialTargetNames = initialTargets.map((Target target) => target.value.name).toList();
        expect(initialTargetNames, isEmpty);
      });

      test('release_build targets for main are not filtered', () {
        final CiYaml releaseYaml = CiYaml(
          slug: Config.flutterSlug,
          branch: 'main',
          config: pb.SchedulerConfig(
            targets: <pb.Target>[
              pb.Target(
                name: 'Linux A',
                properties: <String, String>{'release_build': 'true'},
              ),
              pb.Target(
                name: 'Linux B',
              ),
              pb.Target(
                name: 'Mac A', // Should be ignored on release branches
                bringup: true,
              ),
            ],
          ),
          totConfig: totCIYaml,
        );
        final List<Target> initialTargets = releaseYaml.postsubmitTargets;
        final List<String> initialTargetNames = initialTargets.map((Target target) => target.value.name).toList();
        expect(
          initialTargetNames,
          containsAll(
            <String>[
              'Linux A',
            ],
          ),
        );
      });

      test('validates yaml config', () {
        expect(
          () => CiYaml(
            slug: Config.flutterSlug,
            branch: Config.defaultBranch(Config.flutterSlug),
            config: pb.SchedulerConfig(
              enabledBranches: <String>[
                Config.defaultBranch(Config.flutterSlug),
              ],
              targets: <pb.Target>[
                pb.Target(
                  name: 'Linux A',
                ),
                pb.Target(
                  name: 'Linux B',
                ),
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
      final CiYaml totCIYaml = CiYaml(
        slug: Config.flutterSlug,
        branch: Config.defaultBranch(Config.flutterSlug),
        config: pb.SchedulerConfig(
          enabledBranches: <String>[
            Config.defaultBranch(Config.flutterSlug),
          ],
          targets: <pb.Target>[
            pb.Target(
              name: 'Linux A',
              presubmit: false,
            ),
            pb.Target(
              name: 'Mac A', // Should be ignored on release branches
              bringup: true,
            ),
          ],
        ),
      );
      final CiYaml ciYaml = CiYaml(
        slug: Config.flutterSlug,
        branch: 'flutter-2.4-candidate.3',
        config: pb.SchedulerConfig(
          targets: <pb.Target>[
            pb.Target(
              name: 'Linux A',
              presubmit: true,
            ),
            pb.Target(
              name: 'Linux B',
            ),
            pb.Target(
              name: 'Mac A', // Should be ignored on release branches
              bringup: true,
            ),
          ],
        ),
        totConfig: totCIYaml,
      );

      test('presubmit true target is scheduled though TOT is with presubmit false', () {
        final List<Target> initialTargets = ciYaml.presubmitTargets;
        final List<String> initialTargetNames = initialTargets.map((Target target) => target.value.name).toList();
        expect(
          initialTargetNames,
          containsAll(
            <String>[
              'Linux A',
            ],
          ),
        );
      });
    });
  });
}

/// Wrapper class for table driven design of [CiYaml.enabledBranchesMatchesCurrentBranch].
class EnabledBranchesRegexTest {
  EnabledBranchesRegexTest(this.name, this.branch, this.enabledBranches, [this.expectation = true]);

  final String branch;
  final List<String> enabledBranches;
  final String name;
  final bool expectation;
}

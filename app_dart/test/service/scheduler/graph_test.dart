// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/model/ci_yaml/ci_yaml.dart';
import 'package:cocoon_service/src/model/proto/internal/scheduler.pb.dart';
import 'package:cocoon_service/src/service/config.dart';

import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  useTestLoggerPerTest();

  group('scheduler config', () {
    test('constructs graph with one target', () {
      final singleTargetConfig =
          loadYaml('''
enabled_branches:
  - master
targets:
  - name: A
    builder: builderA
    drone_dimensions:
      - os=Linux
    properties:
      test: abc
      ''')
              as YamlMap?;
      final unCheckedSchedulerConfig =
          SchedulerConfig()..mergeFromProto3Json(singleTargetConfig);
      final schedulerConfig =
          CiYaml(
            type: CiType.any,
            slug: Config.flutterSlug,
            branch: Config.defaultBranch(Config.flutterSlug),
            config: unCheckedSchedulerConfig,
            validate: true,
          ).config;
      expect(schedulerConfig.enabledBranches, <String>['master']);
      expect(schedulerConfig.targets.length, 1);
      final target = schedulerConfig.targets.first;
      expect(target.bringup, false);
      expect(target.name, 'A');
      expect(target.properties, <String, String>{'test': 'abc'});
      expect(target.scheduler, SchedulerSystem.cocoon);
      expect(target.testbed, 'linux-vm');
      expect(target.timeout, 30);
      expect(target.droneDimensions, ['os=Linux']);
    });

    test('throws exception when non-existent scheduler is given', () {
      final targetWithNonexistentScheduler =
          loadYaml('''
enabled_branches:
  - master
targets:
  - name: A
    scheduler: dashatar
      ''')
              as YamlMap?;
      expect(() {
        final unCheckedSchedulerConfig =
            SchedulerConfig()
              ..mergeFromProto3Json(targetWithNonexistentScheduler);
        // ignore: unnecessary_statements
        CiYaml(
          type: CiType.any,
          slug: Config.flutterSlug,
          branch: Config.defaultBranch(Config.flutterSlug),
          config: unCheckedSchedulerConfig,
          validate: true,
        ).config;
      }, throwsA(isA<FormatException>()));
    });

    test('fails when there are duplicate targets', () {
      final configWithDuplicateTargets =
          loadYaml('''
enabled_branches:
  - master
targets:
  - name: A
  - name: A
      ''')
              as YamlMap?;
      final unCheckedSchedulerConfig =
          SchedulerConfig()..mergeFromProto3Json(configWithDuplicateTargets);
      expect(
        () =>
            CiYaml(
              type: CiType.any,
              slug: Config.flutterSlug,
              branch: Config.defaultBranch(Config.flutterSlug),
              config: unCheckedSchedulerConfig,
              validate: true,
            ).config,
        throwsA(
          isA<FormatException>().having(
            (FormatException e) => e.toString(),
            'message',
            contains('ERROR: A already exists in graph'),
          ),
        ),
      );
    });
  });

  group('validate scheduler config and compared with tip of tree targets', () {
    late CiYaml? totConfig;

    setUp(() {
      final totYaml =
          loadYaml('''
enabled_branches:
  - master
targets:
  - name: A
      ''')
              as YamlMap?;
      final unCheckedSchedulerConfig =
          SchedulerConfig()..mergeFromProto3Json(totYaml);
      totConfig = CiYaml(
        type: CiType.any,
        slug: Config.flutterSlug,
        branch: Config.defaultBranch(Config.flutterSlug),
        config: unCheckedSchedulerConfig,
        validate: true,
      );
    });

    test('succeed when no new builders compared with tip of tree builders', () {
      final currentYaml =
          loadYaml('''
enabled_branches:
  - master
targets:
  - name: A
      ''')
              as YamlMap?;
      final unCheckedSchedulerConfig =
          SchedulerConfig()..mergeFromProto3Json(currentYaml);
      expect(
        () => CiYaml(
          type: CiType.any,
          slug: Config.flutterSlug,
          branch: Config.defaultBranch(Config.flutterSlug),
          config: unCheckedSchedulerConfig,
          totConfig: totConfig,
          validate: true,
        ),
        returnsNormally,
      );
    });

    test('succeed when new builder is marked with bringup:true ', () {
      final currentYaml =
          loadYaml('''
enabled_branches:
  - master
targets:
  - name: A
  - name: B
    bringup: true
      ''')
              as YamlMap?;
      final unCheckedSchedulerConfig =
          SchedulerConfig()..mergeFromProto3Json(currentYaml);
      expect(
        () => CiYaml(
          type: CiType.any,
          slug: Config.flutterSlug,
          branch: Config.defaultBranch(Config.flutterSlug),
          config: unCheckedSchedulerConfig,
          totConfig: totConfig,
          validate: true,
        ),
        returnsNormally,
      );
    });

    test('fails when new builder is missing bringup:true ', () {
      final currentYaml =
          loadYaml('''
enabled_branches:
  - master
targets:
  - name: A
  - name: B
      ''')
              as YamlMap?;
      final unCheckedSchedulerConfig =
          SchedulerConfig()..mergeFromProto3Json(currentYaml);
      expect(
        () => CiYaml(
          type: CiType.any,
          slug: Config.flutterSlug,
          branch: Config.defaultBranch(Config.flutterSlug),
          config: unCheckedSchedulerConfig,
          totConfig: totConfig,
          validate: true,
        ),
        throwsA(
          isA<FormatException>().having(
            (FormatException e) => e.toString(),
            'message',
            contains(
              'ERROR: B is a new builder added. it needs to be marked bringup: true',
            ),
          ),
        ),
      );
    });

    test('fails when new builder has bringup set to false ', () {
      final currentYaml =
          loadYaml('''
enabled_branches:
  - master
targets:
  - name: A
  - name: B
    bringup: false
      ''')
              as YamlMap?;
      final unCheckedSchedulerConfig =
          SchedulerConfig()..mergeFromProto3Json(currentYaml);
      expect(
        () => CiYaml(
          type: CiType.any,
          slug: Config.flutterSlug,
          branch: Config.defaultBranch(Config.flutterSlug),
          config: unCheckedSchedulerConfig,
          totConfig: totConfig,
          validate: true,
        ),
        throwsA(
          isA<FormatException>().having(
            (FormatException e) => e.toString(),
            'message',
            contains(
              'ERROR: B is a new builder added. it needs to be marked bringup: true',
            ),
          ),
        ),
      );
    });
  });
}

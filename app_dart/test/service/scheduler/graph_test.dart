// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/model/proto/internal/scheduler.pb.dart';
import 'package:cocoon_service/src/service/scheduler/graph.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  group('scheduler config', () {
    test('constructs graph with one target', () {
      final YamlMap singleTargetConfig = loadYaml('''
enabled_branches:
  - master
targets:
  - name: A
    builder: builderA
    properties:
      test: abc
      ''') as YamlMap;
      final SchedulerConfig schedulerConfig = schedulerConfigFromYaml(singleTargetConfig);
      expect(schedulerConfig.enabledBranches, <String>['master']);
      expect(schedulerConfig.targets.length, 1);
      final Target target = schedulerConfig.targets.first;
      expect(target.bringup, false);
      expect(target.name, 'A');
      expect(target.properties, <String, String>{
        'test': 'abc',
      });
      expect(target.scheduler, SchedulerSystem.cocoon);
      expect(target.testbed, 'linux-vm');
      expect(target.timeout, 30);
    });

    test('throws exception when non-existent scheduler is given', () {
      final YamlMap targetWithNonexistentScheduler = loadYaml('''
enabled_branches:
  - master
targets:
  - name: A
    scheduler: dashatar
      ''') as YamlMap;
      expect(() => schedulerConfigFromYaml(targetWithNonexistentScheduler), throwsA(isA<FormatException>()));
    });

    test('constructs graph with dependency chain', () {
      final YamlMap dependentTargetConfig = loadYaml('''
enabled_branches:
  - master
targets:
  - name: A
  - name: B
    dependencies:
      - A
  - name: C
    dependencies:
      - B
      ''') as YamlMap;
      final SchedulerConfig schedulerConfig = schedulerConfigFromYaml(dependentTargetConfig);
      expect(schedulerConfig.targets.length, 3);
      final Target a = schedulerConfig.targets.first;
      final Target b = schedulerConfig.targets[1];
      final Target c = schedulerConfig.targets[2];
      expect(a.name, 'A');
      expect(b.name, 'B');
      expect(b.dependencies, <String>['A']);
      expect(c.name, 'C');
      expect(c.dependencies, <String>['B']);
    });

    test('constructs graph with parent with two dependents', () {
      final YamlMap twoDependentTargetConfig = loadYaml('''
enabled_branches:
  - master
targets:
  - name: A
  - name: B1
    dependencies:
      - A
  - name: B2
    dependencies:
      - A
      ''') as YamlMap;
      final SchedulerConfig schedulerConfig = schedulerConfigFromYaml(twoDependentTargetConfig);
      expect(schedulerConfig.targets.length, 3);
      final Target a = schedulerConfig.targets.first;
      final Target b1 = schedulerConfig.targets[1];
      final Target b2 = schedulerConfig.targets[2];
      expect(a.name, 'A');
      expect(b1.name, 'B1');
      expect(b1.dependencies, <String>['A']);
      expect(b2.name, 'B2');
      expect(b2.dependencies, <String>['A']);
    });

    test('fails when there are cyclic targets', () {
      final YamlMap configWithCycle = loadYaml('''
enabled_branches:
  - master
targets:
  - name: A
    dependencies:
      - B
  - name: B
    dependencies:
      - A
      ''') as YamlMap;
      expect(
          () => schedulerConfigFromYaml(configWithCycle),
          throwsA(
            isA<FormatException>().having(
              (FormatException e) => e.toString(),
              'message',
              contains('ERROR: A depends on B which does not exist'),
            ),
          ));
    });

    test('fails when there are duplicate targets', () {
      final YamlMap configWithDuplicateTargets = loadYaml('''
enabled_branches:
  - master
targets:
  - name: A
  - name: A
      ''') as YamlMap;
      expect(
          () => schedulerConfigFromYaml(configWithDuplicateTargets),
          throwsA(
            isA<FormatException>().having(
              (FormatException e) => e.toString(),
              'message',
              contains('ERROR: A already exists in graph'),
            ),
          ));
    });

    test('fails when there are multiple dependencies', () {
      final YamlMap configWithMultipleDependencies = loadYaml('''
enabled_branches:
  - master
targets:
  - name: A
  - name: B
  - name: C
    dependencies:
      - A
      - B
      ''') as YamlMap;
      expect(
          () => schedulerConfigFromYaml(configWithMultipleDependencies),
          throwsA(
            isA<FormatException>().having(
              (FormatException e) => e.toString(),
              'message',
              contains('ERROR: C has multiple dependencies which is not supported. Use only one dependency'),
            ),
          ));
    });

    test('fails when dependency does not exist', () {
      final YamlMap configWithMissingTarget = loadYaml('''
enabled_branches:
  - master
targets:
  - name: A
    dependencies:
      - B
      ''') as YamlMap;
      expect(
          () => schedulerConfigFromYaml(configWithMissingTarget),
          throwsA(
            isA<FormatException>().having(
              (FormatException e) => e.toString(),
              'message',
              contains('ERROR: A depends on B which does not exist'),
            ),
          ));
    });
  });
}

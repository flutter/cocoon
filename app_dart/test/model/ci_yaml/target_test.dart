// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/model/proto/protos.dart' as pb;
import 'package:cocoon_service/src/service/scheduler/policy.dart';
import 'package:github/github.dart' as github;
import 'package:test/test.dart';

import '../../src/utilities/entity_generators.dart';

void main() {
  group('Target', () {
    group('properties', () {
      test('default properties', () {
        final target = generateTarget(1);
        expect(target.getProperties(), <String, Object>{
          'bringup': false,
          'dependencies': <String>[],
          'recipe': 'devicelab/devicelab',
        });
      });

      test('properties with ignore_flakiness true', () {
        final target = generateTarget(
          1,
          platform: 'Mac_ios',
          properties: <String, String>{'ignore_flakiness': 'true'},
        );
        expect(target.getIgnoreFlakiness(), true);
      });

      test('properties with ignore_flakiness not present', () {
        final target = generateTarget(
          1,
          platform: 'Mac_ios',
          platformProperties: <String, String>{
            // This should be overrided by the target specific property
            'xcode': 'abc',
          },
        );
        expect(target.getIgnoreFlakiness(), false);
      });

      test('properties with ignore_flakiness in platform properties', () {
        final target = generateTarget(
          1,
          platform: 'Mac_ios',
          platformProperties: <String, String>{
            // This should be overrided by the target specific property
            'ignore_flakiness': 'true',
          },
        );
        expect(target.getIgnoreFlakiness(), true);
      });

      test(
        'properties with ignore_flakiness overrides platform properties',
        () {
          final target = generateTarget(
            1,
            platform: 'Mac_ios',
            platformProperties: <String, String>{
              // This should be overrided by the target specific property
              'ignore_flakiness': 'true',
            },
            properties: <String, String>{'ignore_flakiness': 'false'},
          );
          expect(target.getIgnoreFlakiness(), false);
        },
      );

      test('properties with flakiness_threshold 0.4', () {
        final target = generateTarget(
          1,
          platform: 'Mac_ios',
          properties: <String, String>{'flakiness_threshold': '0.4'},
        );
        expect(target.flakinessThreshold, 0.4);
      });

      test('properties with flakiness_threshold not present', () {
        final target = generateTarget(
          1,
          platform: 'Mac_ios',
          platformProperties: <String, String>{
            // This should be overrided by the target specific property
            'xcode': 'abc',
          },
        );
        expect(target.flakinessThreshold, isNull);
      });

      test('properties with \$flutter/osx_sdk overrides platform properties', () {
        final target = generateTarget(
          1,
          platform: 'Mac',
          platformProperties: <String, String>{
            // This should be overrided by the target specific property
            '\$flutter/osx_sdk':
                '{"sdk_version": "12abc", "runtime_versions": ["ios-11-0", "ios-12-0"]}',
          },
          properties: <String, String>{
            '\$flutter/osx_sdk':
                '{"sdk_version": "14e222b", "runtime_versions": ["ios-13-0", "ios-15-0"]}',
          },
        );
        expect(target.getProperties(), <String, Object>{
          'bringup': false,
          'dependencies': <String>[],
          '\$flutter/osx_sdk': <String, Object>{
            'runtime_versions': ['ios-13-0', 'ios-15-0'],
            'sdk_version': '14e222b',
          },
          'recipe': 'devicelab/devicelab',
        });
      });

      test('tags are parsed from within properties', () {
        final target = generateTarget(
          1,
          platform: 'Linux_build_test',
          platformProperties: <String, String>{
            // This should be overrided by the target specific property
            'android_sdk': 'abc',
          },
          properties: <String, String>{
            'xcode': '12abc',
            'tags': '["devicelab", "android", "linux"]',
          },
        );
        expect(target.tags, ['devicelab', 'android', 'linux']);
      });

      test('we do not blow up if tags are not present', () {
        final target = generateTarget(
          1,
          platform: 'Linux_build_test',
          platformProperties: <String, String>{
            // This should be overrided by the target specific property
            'android_sdk': 'abc',
          },
        );
        expect(target.tags, isEmpty);
      });
    });

    group('dimensions', () {
      test('no dimensions', () {
        final target = generateTarget(1);
        expect(target.getDimensions().length, 0);
      });

      test('platform dimensions and target dimensions are combined', () {
        final target = generateTarget(
          1,
          platform: 'Mac_ios',
          platformDimensions: <String, String>{'signing_cert': 'none'},
          properties: <String, String>{'os': 'abc', 'cpu': 'x64'},
        );
        final dimensions = target.getDimensions();
        expect(dimensions.length, 3);
        expect(dimensions[0].key, 'signing_cert');
        expect(dimensions[0].value, 'none');
        expect(dimensions[1].key, 'os');
        expect(dimensions[1].value, 'abc');
        expect(dimensions[2].key, 'cpu');
        expect(dimensions[2].value, 'x64');
      });

      test('target specific dimensions overrides platform dimensions', () {
        final target = generateTarget(
          1,
          platform: 'Mac_ios',
          platformDimensions: <String, String>{'signing_cert': 'none'},
          dimensions: <String, String>{'signing_cert': 'mac'},
        );
        final dimensions = target.getDimensions();
        expect(dimensions.length, 1);
        expect(dimensions[0].key, 'signing_cert');
        expect(dimensions[0].value, 'mac');
      });

      test(
        'target specific dimensions overrides legacy target specific properties',
        () {
          final target = generateTarget(
            1,
            platform: 'Windows',
            dimensions: <String, String>{'cpu': 'x64'},
            properties: <String, String>{'cpu': 'x32'},
          );
          final dimensions = target.getDimensions();
          expect(dimensions.length, 1);
          expect(dimensions[0].key, 'cpu');
          expect(dimensions[0].value, 'x64');
        },
      );

      test(
        'target specific dimensions overrides legacy platform properties',
        () {
          final target = generateTarget(
            1,
            platform: 'Windows',
            dimensions: <String, String>{'cpu': 'x64'},
            platformProperties: <String, String>{'cpu': 'x32'},
          );
          final dimensions = target.getDimensions();
          expect(dimensions.length, 1);
          expect(dimensions[0].key, 'cpu');
          expect(dimensions[0].value, 'x64');
        },
      );

      test('properties are evaluated as string', () {
        final target = generateTarget(
          1,
          platform: 'Mac_ios',
          platformDimensions: <String, String>{'signing_cert': 'none'},
          properties: <String, String>{'cores': '32'},
        );
        expect(target.getDimensions().length, 2);
      });
    });

    group('scheduler policy', () {
      test('devicelab targets use batch policy', () {
        expect(
          generateTarget(1, platform: 'Linux_android').schedulerPolicy,
          isA<BatchPolicy>(),
        );
      });

      test('devicelab samsung targets use batch policy', () {
        expect(
          generateTarget(1, platform: 'Linux_samsung_a02').schedulerPolicy,
          isA<BatchPolicy>(),
        );
      });

      test('mac host only targets use batch policy', () {
        expect(
          generateTarget(1, platform: 'Mac').schedulerPolicy,
          isA<BatchPolicy>(),
        );
      });

      test('non-cocoon scheduler targets return omit policy', () {
        expect(
          generateTarget(
            1,
            platform: 'Linux_android',
            schedulerSystem: pb.SchedulerSystem.luci,
          ).schedulerPolicy,
          isA<OmitPolicy>(),
        );
      });

      test('vm cocoon targets return batch policy', () {
        expect(
          generateTarget(1, platform: 'Linux').schedulerPolicy,
          isA<BatchPolicy>(),
        );
      });

      test('packages targets use guaranteed policy', () {
        expect(
          generateTarget(
            1,
            platform: 'Mac',
            slug: github.RepositorySlug('flutter', 'packages'),
          ).schedulerPolicy,
          isA<GuaranteedPolicy>(),
        );
      });
    });
  });
}

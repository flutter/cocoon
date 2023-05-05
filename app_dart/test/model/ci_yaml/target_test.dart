// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/model/ci_yaml/target.dart';
import 'package:cocoon_service/src/model/luci/buildbucket.dart';
import 'package:cocoon_service/src/model/proto/protos.dart' as pb;
import 'package:cocoon_service/src/service/scheduler/policy.dart';
import 'package:github/github.dart' as github;
import 'package:test/test.dart';

import '../../src/utilities/entity_generators.dart';

void main() {
  group('Target', () {
    group('properties', () {
      test('default properties', () {
        final Target target = generateTarget(1);
        expect(target.getProperties(), <String, Object>{
          'bringup': false,
          'dependencies': <String>[],
        });
      });

      test('properties with ignore_flakiness true', () {
        final Target target = generateTarget(
          1,
          platform: 'Mac_ios',
          platformProperties: <String, String>{
            // This should be overrided by the target specific property
            'xcode': 'abc',
          },
          properties: <String, String>{
            'xcode': '12abc',
            'ignore_flakiness': 'true',
          },
        );
        expect(target.getIgnoreFlakiness(), true);
      });

      test('properties with ignore_flakiness not present', () {
        final Target target = generateTarget(
          1,
          platform: 'Mac_ios',
          platformProperties: <String, String>{
            // This should be overrided by the target specific property
            'xcode': 'abc',
          },
          properties: <String, String>{
            'xcode': '12abc',
          },
        );
        expect(target.getIgnoreFlakiness(), false);
      });

      test('properties with ignore_flakiness in platform properties', () {
        final Target target = generateTarget(
          1,
          platform: 'Mac_ios',
          platformProperties: <String, String>{
            // This should be overrided by the target specific property
            'ignore_flakiness': 'true',
          },
          properties: <String, String>{
            'xcode': '12abc',
          },
        );
        expect(target.getIgnoreFlakiness(), true);
      });

      test('properties with ignore_flakiness overrides platform properties', () {
        final Target target = generateTarget(
          1,
          platform: 'Mac_ios',
          platformProperties: <String, String>{
            // This should be overrided by the target specific property
            'ignore_flakiness': 'true',
          },
          properties: <String, String>{
            'xcode': '12abc',
            'ignore_flakiness': 'false',
          },
        );
        expect(target.getIgnoreFlakiness(), false);
      });

      test('properties with xcode overrides platform properties', () {
        final Target target = generateTarget(
          1,
          platform: 'Mac_ios',
          platformProperties: <String, String>{
            // This should be overrided by the target specific property
            'xcode': 'abc',
          },
          properties: <String, String>{
            'xcode': '12abc',
          },
        );
        expect(target.getProperties(), <String, Object>{
          'bringup': false,
          'dependencies': <String>[],
          '\$flutter/devicelab_osx_sdk': <String, Object>{
            'sdk_version': '12abc',
          },
          '\$flutter/osx_sdk': <String, Object>{
            'sdk_version': '12abc',
          },
          'xcode': '12abc',
        });
      });

      test('tags are parsed from within properties', () {
        final Target target = generateTarget(
          1,
          platform: 'Linux_build_test',
          platformProperties: <String, String>{
            // This should be overrided by the target specific property
            'android_sdk': 'abc',
          },
          properties: <String, String>{'xcode': '12abc', 'tags': '["devicelab", "android", "linux"]'},
        );
        expect(target.tags, ['devicelab', 'android', 'linux']);
      });

      test('we do not blow up if tags are not present', () {
        final Target target = generateTarget(
          1,
          platform: 'Linux_build_test',
          platformProperties: <String, String>{
            // This should be overrided by the target specific property
            'android_sdk': 'abc',
          },
          properties: <String, String>{
            'xcode': '12abc',
          },
        );
        expect(target.tags, []);
      });

      test('platform properties with xcode', () {
        final Target target = generateTarget(
          1,
          platform: 'Mac_ios',
          platformProperties: <String, String>{
            'xcode': '12abc',
          },
        );
        expect(target.getProperties(), <String, Object>{
          'bringup': false,
          'dependencies': <String>[],
          '\$flutter/devicelab_osx_sdk': <String, Object>{
            'sdk_version': '12abc',
          },
          '\$flutter/osx_sdk': <String, Object>{
            'sdk_version': '12abc',
          },
          'xcode': '12abc',
        });
      });

      test('platform properties with xcode and clean_cache', () {
        final Target target = generateTarget(
          1,
          platform: 'Mac_ios',
          platformProperties: <String, String>{'xcode': '12abc', 'cleanup_xcode_cache': 'true'},
        );
        expect(target.getProperties(), <String, Object>{
          'xcode': '12abc',
          'cleanup_xcode_cache': true,
          'dependencies': <String>[],
          '\$flutter/devicelab_osx_sdk': <String, Object>{'sdk_version': '12abc', 'cleanup_cache': true},
          '\$flutter/osx_sdk': <String, Object>{'sdk_version': '12abc', 'cleanup_cache': true},
          'bringup': false,
        });
      });

      test('platform properties with runtime_versions', () {
        final Target target = generateTarget(
          1,
          platform: 'Mac',
          platformProperties: <String, String>{
            'runtime_versions': '["ios-13-0", "ios-15-0"]',
          },
        );
        expect(target.getProperties(), <String, Object>{
          'bringup': false,
          'dependencies': <String>[],
          '\$flutter/osx_sdk': <String, Object>{
            'runtime_versions': ['ios-13-0', 'ios-15-0'],
          },
          'runtime_versions': ['ios-13-0', 'ios-15-0'],
        });
      });

      test('properties with runtime_versions overrides platform properties', () {
        final Target target = generateTarget(
          1,
          platform: 'Mac',
          platformProperties: <String, String>{
            // This should be overrided by the target specific property
            'runtime_versions': '["ios-13-0", "ios-15-0"]',
          },
          properties: <String, String>{
            'runtime_versions': '["ios-13-0", "ios-15-0"]',
          },
        );
        expect(target.getProperties(), <String, Object>{
          'bringup': false,
          'dependencies': <String>[],
          '\$flutter/osx_sdk': <String, Object>{
            'runtime_versions': ['ios-13-0', 'ios-15-0'],
          },
          'runtime_versions': ['ios-13-0', 'ios-15-0'],
        });
      });

      test('platform properties with xcode and runtime_versions', () {
        final Target target = generateTarget(
          1,
          platform: 'Mac',
          platformProperties: <String, String>{
            'xcode': '12abc',
            'runtime_versions': '["ios-13-0", "ios-15-0"]',
          },
        );
        expect(target.getProperties(), <String, Object>{
          'bringup': false,
          'dependencies': <String>[],
          '\$flutter/osx_sdk': <String, Object>{
            'runtime_versions': ['ios-13-0', 'ios-15-0'],
            'sdk_version': '12abc',
          },
          'xcode': '12abc',
          'runtime_versions': ['ios-13-0', 'ios-15-0'],
        });
      });

      test('platform properties with xcode on Mac_ios', () {
        final Target target = generateTarget(
          1,
          platform: 'Mac_ios',
          platformProperties: <String, String>{
            'xcode': '12abc',
          },
        );
        expect(target.getProperties(), <String, Object>{
          'bringup': false,
          'dependencies': <String>[],
          '\$flutter/osx_sdk': <String, Object>{
            'sdk_version': '12abc',
          },
          '\$flutter/devicelab_osx_sdk': <String, Object>{
            'sdk_version': '12abc',
          },
          'xcode': '12abc',
        });
      });

      test('properties with xcode and runtime_versions overrides platform properties', () {
        final Target target = generateTarget(
          1,
          platform: 'Mac',
          platformProperties: <String, String>{
            // This should be overrided by the target specific property
            'xcode': 'abc',
            'runtime_versions': '["ios-17-0"]',
          },
          properties: <String, String>{
            'xcode': '12abc',
            'runtime_versions': '["ios-13-0", "ios-15-0"]',
          },
        );
        expect(target.getProperties(), <String, Object>{
          'bringup': false,
          'dependencies': <String>[],
          '\$flutter/osx_sdk': <String, Object>{
            'runtime_versions': ['ios-13-0', 'ios-15-0'],
            'sdk_version': '12abc',
          },
          'xcode': '12abc',
          'runtime_versions': ['ios-13-0', 'ios-15-0'],
        });
      });
    });

    group('dimensions', () {
      test('no dimensions', () {
        final Target target = generateTarget(1);
        expect(target.getDimensions().length, 0);
      });

      test('platform dimensions and target dimensions are combined', () {
        final Target target = generateTarget(
          1,
          platform: 'Mac_ios',
          platformDimensions: <String, String>{
            'signing_cert': 'none',
          },
          properties: <String, String>{'os': 'abc', 'cpu': 'x64'},
        );
        final List<RequestedDimension> dimensions = target.getDimensions();
        expect(dimensions.length, 3);
        expect(dimensions[0].key, 'signing_cert');
        expect(dimensions[0].value, 'none');
        expect(dimensions[1].key, 'os');
        expect(dimensions[1].value, 'abc');
        expect(dimensions[2].key, 'cpu');
        expect(dimensions[2].value, 'x64');
      });

      test('target specific dimensions overrides platform dimensions', () {
        final Target target = generateTarget(
          1,
          platform: 'Mac_ios',
          platformDimensions: <String, String>{
            'signing_cert': 'none',
          },
          dimensions: <String, String>{'signing_cert': 'mac'},
        );
        final List<RequestedDimension> dimensions = target.getDimensions();
        expect(dimensions.length, 1);
        expect(dimensions[0].key, 'signing_cert');
        expect(dimensions[0].value, 'mac');
      });

      test('target specific dimensions overrides legacy target specific properties', () {
        final Target target = generateTarget(
          1,
          platform: 'Windows',
          dimensions: <String, String>{'cpu': 'x64'},
          properties: <String, String>{'cpu': 'x32'},
        );
        final List<RequestedDimension> dimensions = target.getDimensions();
        expect(dimensions.length, 1);
        expect(dimensions[0].key, 'cpu');
        expect(dimensions[0].value, 'x64');
      });

      test('target specific dimensions overrides legacy platform properties', () {
        final Target target = generateTarget(
          1,
          platform: 'Windows',
          dimensions: <String, String>{'cpu': 'x64'},
          platformProperties: <String, String>{'cpu': 'x32'},
        );
        final List<RequestedDimension> dimensions = target.getDimensions();
        expect(dimensions.length, 1);
        expect(dimensions[0].key, 'cpu');
        expect(dimensions[0].value, 'x64');
      });

      test('properties are evaluated as string', () {
        final Target target = generateTarget(
          1,
          platform: 'Mac_ios',
          platformDimensions: <String, String>{
            'signing_cert': 'none',
          },
          properties: <String, String>{"cores": "32"},
        );
        expect(target.getDimensions().length, 2);
      });
    });

    group('scheduler policy', () {
      test('devicelab targets use batch policy', () {
        expect(generateTarget(1, platform: 'Linux_android').schedulerPolicy, isA<BatchPolicy>());
      });

      test('devicelab samsung targets use batch policy', () {
        expect(generateTarget(1, platform: 'Linux_samsung_a02').schedulerPolicy, isA<BatchPolicy>());
      });

      test('mac host only targets use batch policy', () {
        expect(generateTarget(1, platform: 'Mac').schedulerPolicy, isA<BatchPolicy>());
      });

      test('non-cocoon scheduler targets return omit policy', () {
        expect(
          generateTarget(1, platform: 'Linux_android', schedulerSystem: pb.SchedulerSystem.luci).schedulerPolicy,
          isA<OmitPolicy>(),
        );
      });

      test('vm cocoon targets return batch policy', () {
        expect(generateTarget(1, platform: 'Linux').schedulerPolicy, isA<BatchPolicy>());
      });

      test('packages targets use guaranteed policy', () {
        expect(
          generateTarget(1, platform: 'Mac', slug: github.RepositorySlug('flutter', 'packages')).schedulerPolicy,
          isA<GuaranteedPolicy>(),
        );
      });
    });
  });
}

// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/model/ci_yaml/target.dart';
import 'package:cocoon_service/src/model/luci/buildbucket.dart';
import 'package:cocoon_service/src/model/proto/protos.dart' as pb;
import 'package:cocoon_service/src/service/scheduler/policy.dart';
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
          'xcode': '12abc',
        });
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
          'xcode': '12abc',
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

      test('platform properties with xcode and runtime_versions on Mac_ios', () {
        final Target target = generateTarget(
          1,
          platform: 'Mac_ios',
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
          },
          '\$flutter/devicelab_osx_sdk': <String, Object>{
            'sdk_version': '12abc',
          },
          'xcode': '12abc',
          'runtime_versions': ['ios-13-0', 'ios-15-0'],
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

      test('dimensions exit', () {
        final Target target = generateTarget(1, properties: <String, String>{'os': 'abc'});
        final List<RequestedDimension> dimensions = target.getDimensions();
        expect(dimensions.length, 1);
        expect(dimensions[0].key, 'os');
        expect(dimensions[0].value, 'abc');
      });

      test('properties are evaluated as string', () {
        final Target target = generateTarget(1, properties: <String, String>{"cores": "32"});
        expect(target.getDimensions().length, 1);
      });
    });

    group('scheduler policy', () {
      test('devicelab targets use batch policy', () {
        expect(generateTarget(1, platform: 'Linux_android').schedulerPolicy, isA<BatchPolicy>());
      });

      test('non-cocoon scheduler targets return omit policy', () {
        expect(generateTarget(1, platform: 'Linux_android', schedulerSystem: pb.SchedulerSystem.luci).schedulerPolicy,
            isA<OmitPolicy>());
      });

      test('vm cocoon targets return guranteed policy', () {
        expect(generateTarget(1, platform: 'Linux').schedulerPolicy, isA<GuranteedPolicy>());
      });
    });
  });
}

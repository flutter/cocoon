// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:buildbucket/buildbucket_pb.dart';
import 'package:github/github.dart';

import '../../service/config.dart';
import '../../service/scheduler/policy.dart';
import '../proto/internal/scheduler.pb.dart' as pb;

/// Wrapper class around [pb.Target] to support aggregate properties.
///
/// Changes here may also need to be upstreamed in:
///  * https://flutter.googlesource.com/infra/+/refs/heads/main/config/lib/ci_yaml/ci_yaml.star
final class Target {
  Target({
    required pb.Target value,
    required this.schedulerConfig,
    required this.slug,
  }) : _value = value;

  /// Underlying [Target] this is based on.
  final pb.Target _value;

  /// The [SchedulerConfig] [_value] is from.
  ///
  /// This is passed for necessary lookups to platform level details.
  final pb.SchedulerConfig schedulerConfig;

  /// The [RepositorySlug] this [Target] is run for.
  final RepositorySlug slug;

  /// Target prefixes that indicate it will run on an ios device.
  static const List<String> iosPlatforms = <String>['mac_ios', 'mac_arm64_ios'];

  /// Dimension list defined in .ci.yaml.
  static List<String> dimensionList = <String>[
    'os',
    'device_os',
    'device_type',
    'mac_model',
    'cores',
    'cpu',
  ];

  static String kIgnoreFlakiness = 'ignore_flakiness';

  static const String kFlakinessThreshold = 'flakiness_threshold';

  /// Gets assembled dimensions for this [pb.Target].
  ///
  /// Swarming dimension doc: https://chromium.googlesource.com/infra/luci/luci-go/+/HEAD/lucicfg/doc/README.md#swarming.dimension
  ///
  /// Target dimensions are prioritized in:
  ///   1. [pb.Target.dimensions]
  ///   1. [pb.Target.properties]
  ///   2. [pb.SchedulerConfig.platformProperties]
  List<RequestedDimension> getDimensions() {
    final dimensionsMap = <String, RequestedDimension>{};

    final platformDimensions = _getPlatformDimensions();
    for (var key in platformDimensions.keys) {
      final value = platformDimensions[key].toString();
      dimensionsMap[key] = RequestedDimension(key: key, value: value);
    }

    final properties = getProperties();
    // TODO(xilaizhang): https://github.com/flutter/flutter/issues/103557
    // remove this logic after dimensions are supported in ci.yaml files
    for (var dimension in dimensionList) {
      if (properties.containsKey(dimension)) {
        final value = properties[dimension].toString();
        dimensionsMap[dimension] = RequestedDimension(
          key: dimension,
          value: value,
        );
      }
    }

    final targetDimensions = _getTargetDimensions();
    for (var key in targetDimensions.keys) {
      final value = targetDimensions[key].toString();
      dimensionsMap[key] = RequestedDimension(key: key, value: value);
    }

    return dimensionsMap.values.toList();
  }

  /// [SchedulerPolicy] this target follows.
  ///
  /// Targets not triggered by Cocoon will not be triggered.
  ///
  /// All targets except from [Config.guaranteedSchedulingRepos] run with [BatchPolicy] to reduce queue time.
  SchedulerPolicy get schedulerPolicy {
    if (_value.scheduler != pb.SchedulerSystem.cocoon) {
      return const OmitPolicy();
    }
    if (Config.guaranteedSchedulingRepos.contains(slug)) {
      return const GuaranteedPolicy();
    }
    return const BatchPolicy();
  }

  /// Get the tags from the defined properties in the ci.
  ///
  /// Return an empty list if no tags are found.
  List<String> get tags {
    final properties = getProperties();
    return (properties.containsKey('tags'))
        ? (properties['tags'] as List).map((e) => e as String).toList()
        : [];
  }

  /// Name of the target.
  String get name => _value.name;

  /// Scheduler system of the target.
  pb.SchedulerSystem get scheduler => _value.scheduler;

  /// Whether the target runs in presubmit.
  bool get presubmit => _value.presubmit;

  /// Whether the target runs in postsubmit.
  bool get postsubmit => _value.postsubmit;

  /// Whether the target should be considered for backfill.
  bool get backfill {
    return _value.hasBackfill()
        ? _value.backfill
        : schedulerPolicy is BatchPolicy;
  }

  /// The target's enabled branches.
  ///
  /// This set is unmodifiable.
  late final Set<String> enabledBranches = Set.unmodifiable(
    _value.enabledBranches,
  );

  /// The target's `runIf` configuration.
  ///
  /// This list is unmodifiable.
  late final List<String> runIf = List.unmodifiable(_value.runIf);

  /// Gets the assembled properties for this [pb.Target].
  ///
  /// Target properties are prioritized in:
  ///   1. [schedulerConfig.platformProperties]
  ///   2. [pb.Target.properties]
  Map<String, Object> getProperties() {
    final platformProperties = _getPlatformProperties();
    final properties = _getTargetProperties();
    final mergedProperties = <String, Object>{}
      ..addAll(platformProperties)
      ..addAll(properties);

    final targetDependencies = <Dependency>[];
    if (properties.containsKey('dependencies')) {
      final rawDeps = properties['dependencies'] as List<dynamic>;
      final deps = rawDeps.map(
        (dynamic rawDep) => Dependency.fromJson(rawDep as Object),
      );
      targetDependencies.addAll(deps);
    }
    final platformDependencies = <Dependency>[];
    if (platformProperties.containsKey('dependencies')) {
      final rawDeps = platformProperties['dependencies'] as List<dynamic>;
      final deps = rawDeps.map(
        (dynamic rawDep) => Dependency.fromJson(rawDep as Object),
      );
      platformDependencies.addAll(deps);
    }
    // Lookup map to make merging [targetDependencies] and [platformDependencies] simpler.
    final mergedDependencies = <String, Dependency>{};
    for (var dep in platformDependencies) {
      mergedDependencies[dep.name] = dep;
    }
    for (var dep in targetDependencies) {
      mergedDependencies[dep.name] = dep;
    }
    mergedProperties['dependencies'] = mergedDependencies.values
        .map((Dependency dep) => dep.toJson())
        .toList();
    mergedProperties['bringup'] = _value.bringup;

    return mergedProperties;
  }

  Map<String, Object> _getTargetDimensions() {
    final dimensions = <String, Object>{};
    for (var key in _value.dimensions.keys) {
      dimensions[key] = _parseProperty(key, _value.dimensions[key]!);
    }

    return dimensions;
  }

  Map<String, Object> _getTargetProperties() {
    final properties = <String, Object>{'recipe': _value.recipe};
    for (var key in _value.properties.keys) {
      properties[key] = _parseProperty(key, _value.properties[key]!);
    }

    return properties;
  }

  Map<String, Object> _getPlatformProperties() {
    if (!schedulerConfig.platformProperties.containsKey(getPlatform())) {
      return <String, Object>{};
    }

    final platformProperties =
        schedulerConfig.platformProperties[getPlatform()]!.properties;
    final properties = <String, Object>{};
    for (var key in platformProperties.keys) {
      properties[key] = _parseProperty(key, platformProperties[key]!);
    }

    return properties;
  }

  Map<String, Object> _getPlatformDimensions() {
    if (!schedulerConfig.platformProperties.containsKey(getPlatform())) {
      return <String, Object>{};
    }

    final platformDimensions =
        schedulerConfig.platformProperties[getPlatform()]!.dimensions;
    final dimensions = <String, Object>{};
    for (var key in platformDimensions.keys) {
      dimensions[key] = _parseProperty(key, platformDimensions[key]!);
    }

    return dimensions;
  }

  /// Converts property strings to their correct type.
  ///
  /// Changes made here should also be made to [_platform_properties] and [_properties] in:
  ///  * https://cs.opensource.google/flutter/infra/+/main:config/lib/ci_yaml/ci_yaml.star
  Object _parseProperty(String key, String value) {
    // Yaml will escape new lines unnecessarily for strings.
    final newLineIssues = <String>[
      'android_sdk_license',
      'android_sdk_preview_license',
    ];
    if (value == 'true') {
      return true;
    } else if (value == 'false') {
      return false;
    } else if (value.startsWith('[') || value.startsWith('{')) {
      return jsonDecode(value) as Object;
    } else if (newLineIssues.contains(key)) {
      return value.replaceAll('\\n', '\n');
    } else if (int.tryParse(value) != null) {
      return int.parse(value);
    } else if (double.tryParse(value) != null) {
      // double parsing must come after int because it parses ints as well.
      // note: Luci (starlark) does not support float/double parsing.
      return double.parse(value);
    }

    return value;
  }

  /// Get the platform of this [Target].
  ///
  /// Platform is extracted as the first word in a target's name.
  String getPlatform() {
    return _value.name.split(' ').first.toLowerCase();
  }

  /// Get the associated LUCI bucket to run this [Target] in.
  String getBucket() {
    return _value.bringup ? 'staging' : 'prod';
  }

  /// Returns value of ignore_flakiness property.
  ///
  /// Returns the value of ignore_flakiness property if
  /// it has been specified, else default returns false.
  bool getIgnoreFlakiness() {
    final properties = getProperties();
    if (properties.containsKey(kIgnoreFlakiness)) {
      return properties[kIgnoreFlakiness] as bool;
    }
    return false;
  }

  /// Returns the value of flakiness_threshold property or the [global].
  double? get flakinessThreshold {
    final properties = getProperties();
    if (properties.containsKey(kFlakinessThreshold)) {
      return properties[kFlakinessThreshold] as double;
    }
    return null;
  }

  /// Whether this target was marked with `properties: release_build: "true"`.
  bool get isReleaseBuild {
    return getProperties()['release_build'] == true;
  }

  /// Whether this target was marked with `bringup: true` in `.ci.yaml`.
  bool get isBringup => _value.bringup;

  @override
  String toString() {
    return 'Target <$_value>';
  }
}

/// Representation of a Flutter dependency.
///
/// See more:
///   * https://flutter.googlesource.com/recipes/+/refs/heads/main/recipe_modules/flutter_deps/api.py
class Dependency {
  Dependency(this.name, this.version);

  /// Constructor for converting from the flutter_deps format.
  factory Dependency.fromJson(Object json) {
    final map = json as Map<String, dynamic>;
    return Dependency(map['dependency']! as String, map['version'] as String?);
  }

  /// Human readable name of the dependency.
  final String name;

  /// CIPD tag to use.
  ///
  /// If null, will use the version set in the flutter_deps recipe_module.
  final String? version;

  Map<String, Object> toJson() {
    return <String, Object>{
      'dependency': name,
      if (version != null) 'version': version!,
    };
  }
}

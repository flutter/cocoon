// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_service/src/service/scheduler/policy.dart';
import 'package:github/github.dart';

import '../../service/config.dart';
import '../luci/buildbucket.dart';
import '../proto/internal/scheduler.pb.dart' as pb;

/// Wrapper class around [pb.Target] to support aggregate properties.
///
/// Changes here may also need to be upstreamed in:
///  * https://flutter.googlesource.com/infra/+/refs/heads/main/config/lib/ci_yaml/ci_yaml.star
class Target {
  Target({
    required this.value,
    required this.schedulerConfig,
    required this.slug,
  });

  /// Underlying [Target] this is based on.
  final pb.Target value;

  /// The [SchedulerConfig] [value] is from.
  ///
  /// This is passed for necessary lookups to platform level details.
  final pb.SchedulerConfig schedulerConfig;

  /// The [RepositorySlug] this [Target] is run for.
  final RepositorySlug slug;

  /// Target prefixes that indicate it will run on an ios device.
  static const List<String> iosPlatforms = <String>['mac_ios', 'mac_arm64_ios'];

  /// Dimension list defined in .ci.yaml.
  static List<String> dimensionList = <String>['os', 'device_os', 'device_type', 'mac_model', 'cores', 'cpu'];

  static String kIgnoreFlakiness = 'ignore_flakiness';

  /// Gets assembled dimensions for this [pb.Target].
  ///
  /// Swarming dimension doc: https://chromium.googlesource.com/infra/luci/luci-go/+/HEAD/lucicfg/doc/README.md#swarming.dimension
  ///
  /// Target dimensions are prioritized in:
  ///   1. [pb.Target.dimensions]
  ///   1. [pb.Target.properties]
  ///   2. [schedulerConfig.platformDimensions]
  List<RequestedDimension> getDimensions() {
    final Map<String, RequestedDimension> dimensionsMap = <String, RequestedDimension>{};

    final Map<String, Object> platformDimensions = _getPlatformDimensions();
    for (String key in platformDimensions.keys) {
      final String value = platformDimensions[key].toString();
      dimensionsMap[key] = RequestedDimension(key: key, value: value);
    }

    final Map<String, Object> properties = getProperties();
    // TODO(xilaizhang): https://github.com/flutter/flutter/issues/103557
    // remove this logic after dimensions are supported in ci.yaml files
    for (String dimension in dimensionList) {
      if (properties.containsKey(dimension)) {
        final String value = properties[dimension].toString();
        dimensionsMap[dimension] = RequestedDimension(key: dimension, value: value);
      }
    }

    final Map<String, Object> targetDimensions = _getTargetDimensions();
    for (String key in targetDimensions.keys) {
      final String value = targetDimensions[key].toString();
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
    if (value.scheduler != pb.SchedulerSystem.cocoon) {
      return OmitPolicy();
    }
    if (Config.guaranteedSchedulingRepos.contains(slug)) {
      return GuaranteedPolicy();
    }
    return BatchPolicy();
  }

  /// Get the tags from the defined properties in the ci.
  ///
  /// Return an empty list if no tags are found.
  List<String> get tags {
    final Map<String, Object> properties = getProperties();
    return (properties.containsKey('tags')) ? (properties['tags'] as List).map((e) => e as String).toList() : [];
  }

  String get getTestName {
    final List<String> words = value.name.split(' ');
    return words.length < 2 ? words[0] : words[1];
  }

  /// Gets the assembled properties for this [pb.Target].
  ///
  /// Target properties are prioritized in:
  ///   1. [schedulerConfig.platformProperties]
  ///   2. [pb.Target.properties]
  Map<String, Object> getProperties() {
    final Map<String, Object> platformProperties = _getPlatformProperties();
    final Map<String, Object> properties = _getTargetProperties();
    final Map<String, Object> mergedProperties = <String, Object>{}
      ..addAll(platformProperties)
      ..addAll(properties);

    final List<Dependency> targetDependencies = <Dependency>[];
    if (properties.containsKey('dependencies')) {
      final List<dynamic> rawDeps = properties['dependencies'] as List<dynamic>;
      final Iterable<Dependency> deps = rawDeps.map((dynamic rawDep) => Dependency.fromJson(rawDep as Object));
      targetDependencies.addAll(deps);
    }
    final List<Dependency> platformDependencies = <Dependency>[];
    if (platformProperties.containsKey('dependencies')) {
      final List<dynamic> rawDeps = platformProperties['dependencies'] as List<dynamic>;
      final Iterable<Dependency> deps = rawDeps.map((dynamic rawDep) => Dependency.fromJson(rawDep as Object));
      platformDependencies.addAll(deps);
    }
    // Lookup map to make merging [targetDependencies] and [platformDependencies] simpler.
    final Map<String, Dependency> mergedDependencies = <String, Dependency>{};
    for (Dependency dep in platformDependencies) {
      mergedDependencies[dep.name] = dep;
    }
    for (Dependency dep in targetDependencies) {
      mergedDependencies[dep.name] = dep;
    }
    mergedProperties['dependencies'] = mergedDependencies.values.map((Dependency dep) => dep.toJson()).toList();
    mergedProperties['bringup'] = value.bringup;

    return mergedProperties;
  }

  Map<String, Object> _getTargetDimensions() {
    final Map<String, Object> dimensions = <String, Object>{};
    for (String key in value.dimensions.keys) {
      dimensions[key] = _parseProperty(key, value.dimensions[key]!);
    }

    return dimensions;
  }

  Map<String, Object> _getTargetProperties() {
    final Map<String, Object> properties = <String, Object>{
      'recipe': value.recipe,
    };
    for (String key in value.properties.keys) {
      properties[key] = _parseProperty(key, value.properties[key]!);
    }

    return properties;
  }

  Map<String, Object> _getPlatformProperties() {
    if (!schedulerConfig.platformProperties.containsKey(getPlatform())) {
      return <String, Object>{};
    }

    final Map<String, String> platformProperties = schedulerConfig.platformProperties[getPlatform()]!.properties;
    final Map<String, Object> properties = <String, Object>{};
    for (String key in platformProperties.keys) {
      properties[key] = _parseProperty(key, platformProperties[key]!);
    }

    return properties;
  }

  Map<String, Object> _getPlatformDimensions() {
    if (!schedulerConfig.platformProperties.containsKey(getPlatform())) {
      return <String, Object>{};
    }

    final Map<String, String> platformDimensions = schedulerConfig.platformProperties[getPlatform()]!.dimensions;
    final Map<String, Object> dimensions = <String, Object>{};
    for (String key in platformDimensions.keys) {
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
    final List<String> newLineIssues = <String>['android_sdk_license', 'android_sdk_preview_license'];
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
    }

    return value;
  }

  /// Get the platform of this [Target].
  ///
  /// Platform is extracted as the first word in a target's name.
  String getPlatform() {
    return value.name.split(' ').first.toLowerCase();
  }

  /// Indicates whether this target should be scheduled via batches.
  ///
  /// DeviceLab targets are special as they run on a host + physical device, and there is limited
  /// capacity in the labs to run them. Their platforms contain one of `android`, `ios`, and `samsung`.
  ///
  /// Mac host only targets are scheduled via patches due to high queue time. This can be relieved
  /// when we have capacity support in Q4/2022.
  bool get shouldBatchSchedule {
    final String platform = getPlatform();
    return platform.contains('android') ||
        platform.contains('ios') ||
        platform.contains('samsung') ||
        platform == 'mac';
  }

  /// Get the associated LUCI bucket to run this [Target] in.
  String getBucket() {
    return value.bringup ? 'staging' : 'prod';
  }

  /// Get the runIf globs for when this target should run.
  ///
  /// If not empty, will include default globs that should trigger all tests.
  List<String> get runIf {
    if (value.runIf.isEmpty) {
      return <String>[];
    }
    return <String>['.ci.yaml', 'DEPS', ...value.runIf];
  }

  /// Returns value of ignore_flakiness property.
  ///
  /// Returns the value of ignore_flakiness property if
  /// it has been specified, else default returns false.
  bool getIgnoreFlakiness() {
    final Map<String, Object> properties = getProperties();
    if (properties.containsKey(kIgnoreFlakiness)) {
      return properties[kIgnoreFlakiness] as bool;
    }
    return false;
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
    final Map<String, dynamic> map = json as Map<String, dynamic>;
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

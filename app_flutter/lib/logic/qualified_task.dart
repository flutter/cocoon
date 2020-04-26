// Copyright (c) 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'package:cocoon_service/protos.dart' show Task, Commit;

/// [Task.stageName] that maps to StageName enums.
// TODO(chillers): Remove these and use StageName enum when available. https://github.com/flutter/cocoon/issues/441
class StageName {
  static const String cirrus = 'cirrus';
  static const String luci = 'chromebot';
  static const String devicelab = 'devicelab';
  static const String devicelabWin = 'devicelab_win';
  static const String devicelabIOs = 'devicelab_ios';
}

/// Base URLs for various endpoints that can relate to a [Task].
const String _flutterGithubSourceUrl = 'https://github.com/flutter/flutter/blob/master';
const String _flutterDashboardUrl = 'https://flutter-dashboard.appspot.com';
const String _cirrusUrl = 'https://cirrus-ci.com/github/flutter/flutter';
const String _cirrusLogUrl = 'https://cirrus-ci.com/build/flutter/flutter';
const String _luciUrl = 'https://ci.chromium.org/p/flutter';

@immutable
class QualifiedTask {
  const QualifiedTask(this.stage, this.task);

  QualifiedTask.fromTask(Task task)
      : stage = task.stageName,
        task = task.name;

  final String stage;
  final String task;

  /// Get the URL for the configuration of this task.
  ///
  /// Devicelab tasks are stored in the flutter/flutter Github repository.
  /// Luci tasks are stored on Luci.
  /// Cirrus tasks are stored on Cirrus.
  ///
  /// Throws [Exception] if [stage] does not match any of the above sources.
  String get sourceConfigurationUrl {
    if (isExternal) {
      return _externalSourceConfigurationUrl;
    }
    return '$_flutterGithubSourceUrl/dev/devicelab/bin/tasks/$task.dart';
  }

  String get _externalSourceConfigurationUrl {
    assert(isExternal);
    switch (stage) {
      case StageName.cirrus:
        return '$_cirrusUrl/master';
      case StageName.luci:
        return _luciSourceConfigurationUrl;
    }
    throw Exception('Failed to get source configuration url for $stage.');
  }

  String get _luciSourceConfigurationUrl {
    switch (task) {
      case 'mac_bot':
        return '$_luciUrl/builders/luci.flutter.prod/Mac';
      case 'linux_bot':
        return '$_luciUrl/builders/luci.flutter.prod/Linux';
      case 'windows_bot':
        return '$_luciUrl/builders/luci.flutter.prod/Windows';
    }
    return _luciUrl;
  }

  /// Whether this task is run in the devicelab or not.
  bool get isDevicelab => stage.contains(StageName.devicelab);

  /// Whether the information from this task is available publically.
  ///
  /// Only devicelab tasks are not available publically.
  bool get isExternal => stage == StageName.luci || stage == StageName.cirrus;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is QualifiedTask && other.stage == stage && other.task == task;
  }

  @override
  int get hashCode => stage.hashCode ^ task.hashCode;
}

/// Get the URL for [Task] to view its log.
///
/// Devicelab tasks can be retrieved via an authenticated API endpoint.
/// Cirrus logs are located via their [Commit.sha].
/// Otherwise, we can redirect to the page that is closest to the logs for [Task].
String logUrl(Task task, {Commit commit}) {
  if (task.stageName == StageName.cirrus && commit != null) {
    return '$_cirrusLogUrl/${commit.sha}';
  } else if (QualifiedTask.fromTask(task).isExternal) {
    // Currently this is just LUCI, but is a catch all if new stages are added.
    return QualifiedTask.fromTask(task).sourceConfigurationUrl;
  }
  return '$_flutterDashboardUrl/api/get-log?ownerKey=${task.key.child.name}';
}

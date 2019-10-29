// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/protos.dart' show Task;

/// A helper class for common utilities done with a [Task].
class TaskHelper {
  /// Base URLs for various endpoints that can relate to a [Task].
  static const String flutterGithubSourceUrl =
      'https://github.com/flutter/flutter/blob/master';
  static const String cirrusUrl =
      'https://cirrus-ci.com/github/flutter/flutter';
  static const String luciUrl = 'https://ci.chromium.org/p/flutter';

  /// [Task.stageName] that maps to StageName enums.
  // TODO(chillers): Remove these and use StageName enum when available. https://github.com/flutter/cocoon/issues/441
  static const String stageCirrus = 'cirrus';
  static const String stageLuci = 'chromebot';
  static const String stageDevicelab = 'devicelab';
  static const String stageDevicelabWin = 'devicelab_win';
  static const String stageDevicelabIOs = 'devicelab_ios';

  /// Get the URL for [Task] that shows its configuration.
  ///
  /// Devicelab tasks are stored in the flutter/flutter Github repository.
  /// Luci tasks are stored on Luci.
  /// Cirrus tasks are stored on Cirrus.
  static String sourceConfigurationUrl(Task task) {
    if (_isExternal(task)) {
      return _externalSourceConfigurationUrl(task);
    }

    return '$flutterGithubSourceUrl/dev/devicelab/bin/tasks/${task.name}.dart';
  }

  static String _externalSourceConfigurationUrl(Task task) {
    if (task.stageName == stageLuci) {
      return _luciSourceConfigurationUrl(task);
    } else if (task.stageName == stageCirrus) {
      return '$cirrusUrl/master';
    }

    throw Exception(
        'Failed to get source configuration url for ${task.stageName}');
  }

  static String _luciSourceConfigurationUrl(Task task) {
    switch (task.name) {
      case 'mac_bot':
        return '$luciUrl/builders/luci.flutter.prod/Mac';
      case 'linux_bot':
        return '$luciUrl/builders/luci.flutter.prod/Linux';
      case 'windows_bot':
        return '$luciUrl/builders/luci.flutter.prod/Windows';
    }

    return luciUrl;
  }

  /// Whether the information from [Task] is available publically.
  ///
  /// Only devicelab tasks are not available publically.
  static bool _isExternal(Task task) =>
      task.stageName == stageLuci || task.stageName == stageCirrus;
}

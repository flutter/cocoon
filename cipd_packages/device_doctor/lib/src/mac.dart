// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:process/process.dart';

import 'health.dart';
import 'utils.dart';

/// The health check for Mac swarming user auto login.
///
/// The `swarming` user auto login is required for Flutter desktop tests which need to run
/// GUI application on Mac.
Future<HealthCheckResult> userAutoLoginCheck(
    {ProcessManager? processManager}) async {
  HealthCheckResult healthCheckResult;
  try {
    final user = await eval(
      'defaults',
      <String>[
        'read',
        '/Library/Preferences/com.apple.loginwindow',
        'autoLoginUser'
      ],
      processManager: processManager,
    );
    // User `swarming` is expected setup for Mac bot auto login.
    if (user == 'swarming') {
      healthCheckResult = HealthCheckResult.success(kUserAutoLoginCheckKey);
    } else {
      healthCheckResult = HealthCheckResult.failure(
          kUserAutoLoginCheckKey, 'swarming user is not setup for auto login');
    }
    // ignore: avoid_catching_errors
  } on BuildFailedException catch (error) {
    healthCheckResult =
        HealthCheckResult.failure(kUserAutoLoginCheckKey, error.toString());
  }
  return healthCheckResult;
}

// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'package:meta/meta.dart';

const String kCocoonEnvironmentVariable = 'COCOON_ENVIRONMENT';

/// Feature flag to indicate the current instance is running in production.
///
/// This is the strictest level of access in Cocoon, and indicates all functionality is running
/// against prod instances, configs, and APIs. It has the ability to block users.
bool get isProduction =>
    (Platform.environment.containsKey(kCocoonEnvironmentVariable) &&
        Platform.environment[kCocoonEnvironmentVariable] == 'prod') ||
    productionTest;

/// Test flag to enable production functionality.
@visibleForTesting
bool productionTest = false;

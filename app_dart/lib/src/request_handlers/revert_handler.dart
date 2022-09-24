// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'package:process/process.dart';
import 'package:meta/meta.dart';

import '../request_handling/body.dart';
import '../request_handling/request_handler.dart';
import '../service/config.dart';

/// Returns [Config.supportedRepos] as a list of repo names.
@immutable
class Revert extends RequestHandler<Body> {
  const Revert({
    required super.config,
  });

  @override
  Future<Body> get() async {
    ProcessManager processManager = const LocalProcessManager();
    processManager.runSync(<String>['git', 'clone', 'https://github.com/flutter/flutter']);
    ProcessResult result = processManager.runSync(<String>['git', 'log'], workingDirectory: 'flutter');
    return Body.forString(result.stdout);
  }
}

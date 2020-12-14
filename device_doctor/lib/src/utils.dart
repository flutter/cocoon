// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;

/// Properties used in device_doctor tool.
/// 
/// {
///   "adb": "/path/to/adb",
///   "idevice_id": "/path/to/idevice_id",
/// }
Map<String, dynamic> properties;

final Logger logger = Logger('DeviceDoctor');

void fail(String message) {
  throw BuildFailedError(message);
}

class BuildFailedError extends Error {
  BuildFailedError(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Creates a directory from the given path, or multiple path parts by joining
/// them using OS-specific file path separator.
Directory dir(String thePath,
    [String part2, String part3, String part4, String part5, String part6, String part7, String part8]) {
  return Directory(path.join(thePath, part2, part3, part4, part5, part6, part7, part8));
}

Future<dynamic> inDirectory(dynamic directory, Future<dynamic> action()) async {
  String previousCwd = path.current;
  try {
    cd(directory);
    return await action();
  } finally {
    cd(previousCwd);
  }
}

void cd(dynamic directory) {
  Directory d;
  if (directory is String) {
    d = dir(directory);
  } else if (directory is Directory) {
    d = directory;
  } else {
    throw 'Unsupported type ${directory.runtimeType} of $directory';
  }

  if (!d.existsSync()) throw 'Cannot cd into directory that does not exist: $directory';
}

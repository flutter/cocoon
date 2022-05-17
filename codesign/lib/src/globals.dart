// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: unnecessary_string_escapes

import 'package:args/args.dart';

class ConductorException implements Exception {
  ConductorException(this.message);

  final String message;

  @override
  String toString() => 'Exception: $message';
}

/// Translate CLI arg names to env variable names.
///
/// For example, 'state-file' -> 'STATE_FILE'.
String fromArgToEnvName(String argName) {
  return argName.toUpperCase().replaceAll(r'-', r'_');
}

/// Either return the value from [env] or fall back to [argResults].
///
/// If the key does not exist in either the environment or CLI args, throws a
/// [ConductorException].
///
/// The environment is favored over CLI args since the latter can have a default
/// value, which the environment should be able to override.
String? getValueFromEnvOrArgs(
  String name,
  ArgResults argResults,
  Map<String, String> env, {
  bool allowNull = false,
}) {
  final String envName = fromArgToEnvName(name);
  if (env[envName] != null) {
    return env[envName];
  }
  final String? argValue = argResults[name] as String?;
  if (argValue != null) {
    return argValue;
  }

  if (allowNull) {
    return null;
  }
  throw ConductorException('Expected either the CLI arg --$name or the environment variable $envName '
      'to be provided!');
}
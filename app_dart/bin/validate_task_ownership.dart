// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/foundation/utils.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:github/github.dart';
import 'package:http/http.dart' as http;

/// Remote check based on flutter `repo` and the commit `ref`.
///
/// This currently supports `flutter/flutter` only.
Future<List<String>> remoteCheck(String repo, String ref) async {
  final ciYamlContent = await githubFileContent(
    RepositorySlug('flutter', repo),
    kCiYamlPath,
    httpClientProvider: http.Client.new,
    ref: ref,
  );
  final testOwnersContent = await githubFileContent(
    RepositorySlug('flutter', repo),
    kTestOwnerPath,
    httpClientProvider: http.Client.new,
    ref: ref,
  );

  final noOwnerBuilders = validateOwnership(
    ciYamlContent,
    testOwnersContent,
    unfilteredTargets: true,
  );
  return noOwnerBuilders;
}

/// Local check is based on paths to the local `.ci.yaml` and `TESTOWNERS` files.
List<String> localCheck(String ciYamlPath, String testOwnersPath) {
  const FileSystem fs = LocalFileSystem();
  final ciYamlFile = fs.file(ciYamlPath);
  final testOwnersFile = fs.file(testOwnersPath);
  if (!ciYamlFile.existsSync() || !testOwnersFile.existsSync()) {
    print('Make sure ciYamlPath and testOwnersPath exist.');
    io.exit(1);
  }
  final noOwnerBuilders = validateOwnership(
    ciYamlFile.readAsStringSync(),
    testOwnersFile.readAsStringSync(),
    unfilteredTargets: true,
  );
  return noOwnerBuilders;
}

/// Validates task ownership.
///
/// It expects two parameters for remote validation: the flutter `repo` and the `commit`.
///
/// It expects three parameters for local validation: `local` arg, the full path to the config
/// file (`.ci.yaml`), and the full pathto the `TESTOWNERS` file.
Future<void> main(List<String> args) async {
  if (args.length != 2 && args.length != 3) {
    print('validate_task_ownership.dart \$repo \$sha');
    print(
      'validate_task_ownership.dart local \$local_ci_yaml \$local_TESTOWNERS',
    );
    io.exit(1);
  }
  List<String> noOwnerBuilders;
  if (args.length == 2) {
    noOwnerBuilders = await remoteCheck(args[0], args[1]);
  } else {
    noOwnerBuilders = localCheck(args[1], args[2]);
  }
  if (noOwnerBuilders.isNotEmpty) {
    print('# Test ownership check failed.');
    print('Builders missing owner: $noOwnerBuilders');
    print(
      'Please define ownership in https://github.com/flutter/flutter/blob/master/TESTOWNERS',
    );
    io.exit(1);
  } else {
    print('# Test ownership check succeeded.');
  }
}

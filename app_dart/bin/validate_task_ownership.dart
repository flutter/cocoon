// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/protos.dart';
import 'package:cocoon_service/src/foundation/providers.dart';
import 'package:cocoon_service/src/foundation/typedefs.dart';
import 'package:cocoon_service/src/foundation/utils.dart';
import 'package:cocoon_service/src/request_handlers/flaky_handler_utils.dart';
import 'package:yaml/yaml.dart';

/// Remote check based on flutter `repo` and the commit `ref`.
///
/// This currently supports `flutter/flutter` only.
Future<List<String>> remoteCheck(String repo, String ref) async {
  const HttpClientProvider httpClientProvider = Providers.freshHttpClient;
  final String ciYamlContent =
      await githubFileContent('flutter/$repo/$ref/.ci.yaml', httpClientProvider: httpClientProvider);
  final String testOwnersContent =
      await githubFileContent('flutter/$repo/$ref/TESTOWNERS', httpClientProvider: httpClientProvider);
  
  final List<String> noOwnerBuilders = validateOwnership(ciYamlContent, testOwnersContent);
  return noOwnerBuilders;
}

/// Local check is based on paths to the local `.ci.yaml` and `TESTOWNERS` files.
List<String> localCheck(String ciYamlPath, String testOwnersPath) {
  final File ciYamlFile = File(ciYamlPath);
  final File testOwnersFile = File(testOwnersPath);
  if (!ciYamlFile.existsSync() || !testOwnersFile.existsSync()) {
    print('Make sure ciYamlPath and testOwnersPath exist.');
    exit(1);
  }
  final List<String> noOwnerBuilders =
      validateOwnership(ciYamlFile.readAsStringSync(), testOwnersFile.readAsStringSync());
  return noOwnerBuilders;
}

/// Validate test ownership defined in `testOwnersContenct` for tests configured in `ciYamlContent`.
List<String> validateOwnership(String ciYamlContent, String testOwnersContenct) {
  final List<String> noOwnerBuilders = <String>[];
  final YamlMap ciYaml = loadYaml(ciYamlContent) as YamlMap;
  final SchedulerConfig schedulerConfig = schedulerConfigFromYaml(ciYaml);
  for (Target target in schedulerConfig.targets) {
    final String builder = target.name;
    final String owner = getTestOwner(builder, getTypeForBuilder(builder, ciYaml), testOwnersContenct);
    print('$builder: $owner');
    if (owner == null) {
      noOwnerBuilders.add(builder);
    }
  }
  return noOwnerBuilders;
}

/// Validates task ownership.
///
/// It expects two parameters for remote validation: the flutter `repo` and the `commit`.
///
/// It expects three parameters for remote validation: `local` arg, the full path to the config
/// file (`.ci.yaml`), and the full pathto the `TESTOWNERS` file.
Future<void> main(List<String> args) async {
  if (args.length != 2 && args.length != 3) {
    print('validate_task_ownership.dart \$repo \$sha');
    print('generate_jspb.dart local \$local_ci_yaml \$lcoal_TESTOWNERS');
    exit(1);
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
    print('Please define ownership in https://github.com/flutter/flutter/blob/master/TESTOWNERS');
    exit(1);
  } else {
    print('# Test ownership check succeeded.');
  }
}

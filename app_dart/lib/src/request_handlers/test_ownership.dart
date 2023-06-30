// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/request_handlers/flaky_handler_utils.dart';
import '../../protos.dart' as pb;

abstract class TestOwner {
  factory TestOwner(BuilderType builderType) {
    switch (builderType) {
      case BuilderType.devicelab:
        return DeviceLabTestOwner();
      case BuilderType.firebaselab:
        return FirebaseLabTestOwner();
      case BuilderType.frameworkHostOnly:
        return FrameworkHostOnlyTestOwner();
      case BuilderType.shard:
        return ShardTestOwner();
      default:
        return UnknownTestOwner();
    }
  }

  TestOwnership getTestOwnership(
    pb.Target target,
    String testOwnersContent,
  );
}

Team teamFromString(String teamString) {
  switch (teamString) {
    case 'flutter/framework':
      return Team.framework;
    case 'flutter/engine':
      return Team.engine;
    case 'flutter/tool':
      return Team.tool;
    case 'flutter/web':
      return Team.web;
  }
  return Team.unknown;
}

String getTestNameFromTargetName(String targetName) {
  // The builder names is in the format '<platform> <test name>'.
  final List<String> words = targetName.split(' ');
  return words.length < 2 ? words[0] : words[1];
}

class DeviceLabTestOwner implements TestOwner {
  DeviceLabTestOwner();

  @override
  TestOwnership getTestOwnership(
    pb.Target target,
    String testOwnersContent,
  ) {
    String? owner;
    Team? team;
    final String testName = target.properties['task_name']!;
    // The format looks like this:
    //   /dev/devicelab/bin/tasks/dart_plugin_registry_test.dart @stuartmorgan @flutter/plugin
    final RegExpMatch? match = devicelabTestOwners.firstMatch(testOwnersContent);
    if (match != null && match.namedGroup(kOwnerGroupName) != null) {
      final List<String> lines = match
          .namedGroup(kOwnerGroupName)!
          .split('\n')
          .where((String line) => line.isNotEmpty && !line.startsWith('#'))
          .toList();

      for (final String line in lines) {
        final List<String> words = line.trim().split(' ');
        // e.g. words = ['/xxx/xxx/xxx_test.dart', '@stuartmorgan' '@flutter/tool']
        if (words[0].endsWith('$testName.dart')) {
          owner = words[1].substring(1); // Strip out the lead '@'
          team = words.length < 3 ? Team.unknown : teamFromString(words[2].substring(1)); // Strip out the lead '@'
          break;
        }
      }
    }

    return TestOwnership(owner, team);
  }
}

class ShardTestOwner implements TestOwner {
  @override
  TestOwnership getTestOwnership(
    pb.Target target,
    String testOwnersContent,
  ) {
    // The format looks like this:
    //   # build_tests @zanderso @flutter/tool
    final String testName = getTestNameFromTargetName(target.name);
    String? owner;
    Team? team;
    final RegExpMatch? match = shardTestOwners.firstMatch(testOwnersContent);
    if (match != null && match.namedGroup(kOwnerGroupName) != null) {
      final List<String> lines =
          match.namedGroup(kOwnerGroupName)!.split('\n').where((String line) => line.contains('@')).toList();

      for (final String line in lines) {
        final List<String> words = line.trim().split(' ');
        // e.g. words = ['#', 'build_test', '@zanderso' '@flutter/tool']
        if (testName.contains(words[1])) {
          owner = words[2].substring(1); // Strip out the lead '@'
          team = words.length < 4 ? Team.unknown : teamFromString(words[3].substring(1)); // Strip out the lead '@'
          break;
        }
      }
    }

    return TestOwnership(owner, team);
  }
}

class FrameworkHostOnlyTestOwner implements TestOwner {
  @override
  TestOwnership getTestOwnership(
    pb.Target target,
    String testOwnersContent,
  ) {
    final String testName = getTestNameFromTargetName(target.name);
    String? owner;
    Team? team;
    // The format looks like this:
    //   # Linux analyze
    //   /dev/bots/analyze.dart @HansMuller @flutter/framework
    final RegExpMatch? match = frameworkHostOnlyTestOwners.firstMatch(testOwnersContent);
    if (match != null && match.namedGroup(kOwnerGroupName) != null) {
      final List<String> lines =
          match.namedGroup(kOwnerGroupName)!.split('\n').where((String line) => line.isNotEmpty).toList();
      int index = 0;
      while (index < lines.length) {
        if (lines[index].startsWith('#')) {
          // Multiple tests can share same test file and ownership.
          // e.g.
          //   # Linux docs_test
          //   # Linux docs_public
          //   /dev/bots/docs.sh @HansMuller @flutter/framework
          bool isTestDefined = false;
          while (lines[index].startsWith('#') && index + 1 < lines.length) {
            final List<String> commentWords = lines[index].trim().split(' ');
            if (testName.contains(commentWords[2])) {
              isTestDefined = true;
            }
            index += 1;
          }
          if (isTestDefined) {
            final List<String> ownerWords = lines[index].trim().split(' ');
            // e.g. ownerWords = ['/xxx/xxx/xxx_test.dart', '@HansMuller' '@flutter/framework']
            owner = ownerWords[1].substring(1); // Strip out the lead '@'
            team = ownerWords.length < 3
                ? Team.unknown
                : teamFromString(ownerWords[2].substring(1)); // Strip out the lead '@'
            break;
          }
        }
        index += 1;
      }
    }

    return TestOwnership(owner, team);
  }
}

class FirebaseLabTestOwner implements TestOwner {
  @override
  TestOwnership getTestOwnership(
    pb.Target target,
    String testOwnersContent,
  ) {
    final String testName = getTestNameFromTargetName(target.name);
    String? owner;
    Team? team;

    // The format looks like this for builder `Linux firebase_abstrac_method_smoke_test`:
    //   /dev/integration_tests/abstrac_method_smoke_test @blasten @flutter/android
    final RegExpMatch? match = firebaselabTestOwners.firstMatch(testOwnersContent);
    if (match != null && match.namedGroup(kOwnerGroupName) != null) {
      final List<String> lines = match
          .namedGroup(kOwnerGroupName)!
          .split('\n')
          .where((String line) => line.isNotEmpty && !line.startsWith('#'))
          .toList();

      for (final String line in lines) {
        final List<String> words = line.trim().split(' ');
        final List<String> dirs = words[0].split('/').toList();
        if (testName.contains(dirs.last)) {
          owner = words[1].substring(1); // Strip out the lead '@'
          team = words.length < 3 ? Team.unknown : teamFromString(words[2].substring(1)); // Strip out the lead '@'
          break;
        }
      }
    }

    return TestOwnership(owner, team);
  }
}

class UnknownTestOwner implements TestOwner {
  @override
  TestOwnership getTestOwnership(
    pb.Target target,
    String testOwnersContent,
  ) {
    return TestOwnership(null, Team.unknown);
  }
}

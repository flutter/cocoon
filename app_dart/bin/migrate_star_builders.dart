import 'dart:convert' show jsonDecode;
import 'dart:io' as io;

import 'package:args/args.dart';
import 'package:cocoon_service/protos.dart';
import 'package:cocoon_service/src/service/luci.dart';

Future<void> main(List<String> args) async {
  final ArgParser parser = ArgParser()
    ..addOption(
      'try-builders',
      abbr: 't',
      help: 'Path to a repo\'s `try_builders.json` config file.',
    )
    ..addOption(
      'prod-builders',
      abbr: 'p',
      help: 'Path to a repo\'s `prod_builders.json` config file.',
    );
  final ArgResults results = parser.parse(args);
  final String tryBuildersPath = results['try-builders'] as String;
  final String prodBuildersPath = results['prod-builders'] as String;

  run(
    tryBuildersPath: tryBuildersPath,
    prodBuildersPath: prodBuildersPath,
  );
}

void run({
  String tryBuildersPath,
  String prodBuildersPath,
}) {
  parseJson(
    tryBuildersPath,
    presubmit: true,
  );
  parseJson(
    prodBuildersPath,
    postsubmit: true,
  );
}

void parseJson(String path, {bool presubmit = false, bool postsubmit = false}) {
  if (path == null) {
    return;
  }

  final String buildersString = io.File(path).readAsStringSync();
  final Map<String, dynamic> jsonMap = jsonDecode(buildersString) as Map<String, dynamic>;
  final List<dynamic> builderList = jsonMap['builders'] as List<dynamic>;
  final Iterable<LuciBuilder> builders = builderList
      .map((dynamic builder) => LuciBuilder.fromJson(builder as Map<String, dynamic>))
      .where((LuciBuilder element) => element.enabled ?? true);
  final Iterable<Target> targets = builders.map((LuciBuilder builder) => Target(
        name: builder.taskName ?? builder.name,
        scheduler: SchedulerSystem.luci,
        presubmit: presubmit,
        postsubmit: postsubmit,
        builder: builder.name,
        runIf: builder.runIf,
        bringup: builder.flaky,
      ));

  final SchedulerConfig config = SchedulerConfig(enabledBranches: <String>['master'], targets: targets);
  writeYaml(config);
}

void writeYaml(SchedulerConfig config) {
  final List<String> configYaml = <String>['enabled_branches:'];
  for (String branch in config.enabledBranches) {
    configYaml.add('  - $branch');
  }
  configYaml.add('');
  for (Target target in config.targets) {
    configYaml.add('- name: ${target.name}');
    configYaml.add('  builder: ${target.builder}');
    if (target.bringup) {
      configYaml.add('  bringup: ${target.bringup}');
    }
    if (target.presubmit) {
      configYaml.add('  presubmit: ${target.presubmit}');
    }
    if (target.postsubmit) {
      configYaml.add('  postsubmit: ${target.postsubmit}');
    }
    if (target.scheduler != SchedulerSystem.cocoon) {
      configYaml.add('  scheduler: ${target.scheduler}');
    }
    if (target.runIf.isNotEmpty) {
      configYaml.add('  runIf: ${target.runIf}');
      for (String regex in target.runIf) {
        configYaml.add('    - $regex');
      }
    }
  }
  print(configYaml.join('\n'));
}
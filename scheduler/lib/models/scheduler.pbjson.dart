///
//  Generated code. Do not modify.
//  source: lib/models/scheduler.proto
//
// @dart = 2.7
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

const SchedulerSystem$json = const {
  '1': 'SchedulerSystem',
  '2': const [
    const {'1': 'cocoon', '2': 1},
    const {'1': 'luci', '2': 2},
  ],
};

const SchedulerConfig$json = const {
  '1': 'SchedulerConfig',
  '2': const [
    const {'1': 'targets', '3': 1, '4': 3, '5': 11, '6': '.Target', '10': 'targets'},
    const {'1': 'enabled_branches', '3': 2, '4': 3, '5': 9, '10': 'enabledBranches'},
  ],
};

const Target$json = const {
  '1': 'Target',
  '2': const [
    const {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'dependencies', '3': 2, '4': 3, '5': 9, '10': 'dependencies'},
    const {'1': 'bringup', '3': 3, '4': 1, '5': 8, '7': 'false', '10': 'bringup'},
    const {'1': 'timeout', '3': 4, '4': 1, '5': 5, '7': '30', '10': 'timeout'},
    const {'1': 'testbed', '3': 5, '4': 1, '5': 9, '7': 'linux-vm', '10': 'testbed'},
    const {'1': 'properties', '3': 6, '4': 3, '5': 11, '6': '.Target.PropertiesEntry', '10': 'properties'},
    const {'1': 'builder', '3': 7, '4': 1, '5': 9, '10': 'builder'},
    const {'1': 'scheduler', '3': 8, '4': 1, '5': 14, '6': '.SchedulerSystem', '7': 'cocoon', '10': 'scheduler'},
    const {'1': 'presubmit', '3': 9, '4': 1, '5': 8, '7': 'false', '10': 'presubmit'},
    const {'1': 'postsubmit', '3': 10, '4': 1, '5': 8, '7': 'false', '10': 'postsubmit'},
    const {'1': 'run_if', '3': 11, '4': 3, '5': 9, '10': 'runIf'},
    const {'1': 'enabled_branches', '3': 12, '4': 3, '5': 9, '10': 'enabledBranches'},
  ],
  '3': const [Target_PropertiesEntry$json],
};

const Target_PropertiesEntry$json = const {
  '1': 'PropertiesEntry',
  '2': const [
    const {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    const {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': const {'7': true},
};

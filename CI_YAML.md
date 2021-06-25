# Cocoon Scheduler

This Dart project contains logic for constructing infrastructure configs
to validate commits in the repositories owned by Flutter.

## ci.yaml

This is the config file in a repository used to tell Cocoon what tasks are used
to validate commits. It includes both the tasks used in presubmit and postsubmit.

In addition, it supports tasks from different infrastructures as long as cocoon
supports that `scheduler`. Only `luci` and `cocoon` are supported, but contributions
are welcome.

Example config:
```yaml
# /.ci.yaml
enabled_branches:
  - master
targets:
# A Target is an individual unit of work that is scheduled by Flutter infra
# Target's are composed of the following properties:
# name: A human readable string to uniquely identify this target.
# bringup: Whether this target is under active development and should not block the tree.
#          If true, will not run in presubmit and will not block postsubmit.
# scheduler: String identifying where this target is triggered.
#            Currently supports cocoon and luci.
# builder: If LUCI based, the string of the builder name this target is scheduled on.
# presubmit: Whether to run this target on presubmit (defaults to true).
# postsubmit: Whether to run this target on postsubmit (defaults to true).
# run_if: List of path regexes that can trigger this target on presubmit.
#         If none are passed, will always run in presubmit.
# enabled_branches: List of strings of branches this target can run on.
#                   This overrides the global enabled_branches.
#
# Minimal example:
# Linux analyze will run on all presubmit and in postsubmit based on the LUCI builder `Linux analyze`.
 - name: Linux analyze
   builder: Linux analyze
#
# Bringup example:
# Linux licenses will run on postsubmit based on the LUCI builder `Linux analyze`,
# but it also passes the properties `analyze=true` to the builder. Since `bringup=true`,
# presubmit is not run, and postsubmit runs will not block the tree.
 - name: Linux licenses
   builder: Linux analyze
   bringup: true
   properties:
     - analyze: license
```

## External Tests

Cocoon supports tests that are not owned by Flutter infrastructure. By default, these should not block the tree but act as FYI to the gardeners.

1. Contact flutter-infra@ with your request
2. Add your system to SchedulerSystem (https://github.com/flutter/cocoon/blob/master/app_dart/lib/src/model/proto/internal/scheduler.proto)
3. Add your service account to https://github.com/flutter/cocoon/blob/master/app_dart/lib/src/request_handling/swarming_authentication.dart
4. Add a custom frontend icon - https://github.com/flutter/cocoon/blob/master/app_flutter/lib/widgets/task_icon.dart
5. Add a custom log link - https://github.com/flutter/cocoon/blob/master/app_flutter/lib/logic/qualified_task.dart
6. Wait for the next prod roll (every weekday)
7. Add a target to `.ci.yaml`
```yaml
# .ci.yaml
- name: my_external_test_a
  # External tests should not block the tree
  bringup: true
  presubmit: false
  scheduler: my_external_location
```
9. Send updates to `https://flutter-dashboard.appspot.com/api/update-task-status` - https://github.com/flutter/cocoon/blob/master/app_dart/lib/src/request_handlers/update_task_status.dart

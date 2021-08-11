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
# presubmit: Whether to run this target on presubmit (defaults to true).
# postsubmit: Whether to run this target on postsubmit (defaults to true).
# run_if: List of path regexes that can trigger this target on presubmit.
#         If none are passed, will always run in presubmit.
# enabled_branches: List of strings of branches this target can run on.
#                   This overrides the global enabled_branches.
#
# Minimal example:
# Linux analyze will run on all presubmit and in postsubmit.
 - name: Linux analyze
#
# Bringup example:
# Linux licenses will run on postsubmit, but it also passes the properties
# `analyze=true` to the builder. Since `bringup=true`, presubmit is not run,
# and postsubmit runs will not block the tree.
 - name: Linux licenses
   bringup: true
   properties:
     - analyze: license

#
# Tags example:
# This test will be categorized as host only framework test.
 - name: Linux analyze
   properties:
     tags: >-
       ["framework", "hostonly"]
```

## Upgrading dependencies
1. Find the cipd ref to upgrade to
    - If this is a Flutter managed package, look up its docs on uploading a new version
    - For example, JDK is at https://chrome-infra-packages.appspot.com/p/flutter_internal/java/openjdk/linux-amd64
2. In `ci.yaml`, find a target that would be impacted by this change
    - Duplicate the target with a bringup version (will only run in postsubmit, non-blocking)
    - Override the `version` in like `{"dependency": "open_jdk", "version": "11"}
      ```yaml
      - name: Linux Host Engine Java 11
        recipe: engine
        properties:
          build_host: "true"
          dependencies: >-
          [
              {"dependency": "open_jdk", "version": "11"}
          ]
        timeout: 60
        scheduler: luci
    ```
    - Send PR, wait for it to propagate in LUCI
3. If the target in (2) is red, send patches to get it green.
4. When the bringup builder has validated the new dependency, and there is confidence
   the new dependency is compatible, roll all targets to the new version in `.ci.yaml`.
    - This is usually defined under `platform_properties`
    - Remove the bringup builder from (2)

## External Tests

Cocoon supports tests that are not owned by Flutter infrastructure. By default, these should not block the tree but act as FYI to the gardeners.

1. Contact flutter-infra@ with your request (go/flutter-infra-office-hours)
2. Add your system to SchedulerSystem (https://github.com/flutter/cocoon/blob/master/app_dart/lib/src/model/proto/internal/scheduler.proto)
3. Add your service account to https://github.com/flutter/cocoon/blob/master/app_dart/lib/src/request_handling/swarming_authentication.dart
4. Add a custom frontend icon - https://github.com/flutter/cocoon/blob/master/app_flutter/lib/widgets/task_icon.dart
5. Add a custom log link - https://github.com/flutter/cocoon/blob/master/app_flutter/lib/logic/qualified_task.dart
6. Wait for the next prod roll (every weekday)
7. Add a target to `.ci.yaml`
   ```yaml
   # .ci.yaml
   # Name is an arbitrary string that will show on the build dashboard
   - name: my_external_test_a
     # External tests should not block the tree
     bringup: true
     presubmit: false
     # Scheduler must match what was added to scheduler.proto (any unique name works)
     scheduler: my_external_location
   ```
8. Send updates to `https://flutter-dashboard.appspot.com/api/update-task-status` - https://github.com/flutter/cocoon/blob/master/app_dart/lib/src/request_handlers/update_task_status.dart

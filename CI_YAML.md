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

# Enabled branches is a list of regexes, with the assumption that these are full line matches.
# Internally, Cocoon prefixes these with $ and suffixes with ^ to enable matches.
enabled_branches:
  - main
  - flutter-\\d+\\.\\d+-candidate\\.\\d+

# Platform properties defines common properties shared among targets from the same platform.
platform_properties:
  linux:
    properties:
      # os will be inherited by all Linux targets, but it can be overrided at the target level
      os: Linux

targets:
# A Target is an individual unit of work that is scheduled by Flutter infra
# Target's are composed of the following properties:
# name: A human readable string to uniquely identify this target.
#       The first word indicates the platform this test will be run on. This should match
#       to an existing platform under platform_properties.
# recipes: LUCI recipes the target follows to run tests
#          https://flutter.googlesource.com/recipes/+/refs/heads/main/recipes/
# bringup: Whether this target is under active development and should not block the tree.
#          If true, will not run in presubmit and will not block postsubmit.
# presubmit: Whether to run this target on presubmit (defaults to true).
# postsubmit: Whether to run this target on postsubmit (defaults to true).
# run_if: List of path regexes that can trigger this target on presubmit.
#         If none are passed, it will evaluare run_if_not. If both are empty the target
#         will always run in presubmit.
# run_if_not: List of path regexes used to filter out presubmit targets. The target will
#         be run only if the files changed do not match any paths in this list. If run_if
#         is provided and not empty run_if_not will be ignored.
# enabled_branches: List of strings of branches this target can run on.
#                   This overrides the global enabled_branches.
# properties: A map of string, string. Values are parsed to their closest data model.
# postsubmit_properties: Properties that are only run on postsubmit.
# timeout: Integer defining whole build execution time limit for all steps in minutes.
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
# Postsubmit runs will be passed "upload_metrics: true".
 - name: Linux analyze
   properties:
     tags: >-
       ["framework", "hostonly"]
   postsubmit_properties:
     - upload_metrics: "true"

#
# Devicelab example:
# For tests that are located https://github.com/flutter/flutter/tree/master/dev/devicelab/bin/tasks:
# 1) target name follows format of `<platform> <taskname>`
# 2) properties
#    2.1) update `tags` based on hosts, devices, and tests type. These tags will be used for statistic analysis.
#    2.2) a `taskname` property is required, which should match the task name
#
# Here is the target config for a task named: `analyzer_benchmark.dart`.
 - name: Linux_android analyzer_benchmark
   recipe: devicelab/devicelab_drone
   presubmit: false
   properties:
     tags: >
       ["devicelab", "android", "linux"]
     task_name: analyzer_benchmark
```

### Adding new targets

All new targets should be added as `bringup: true` to ensure they do not block the tree.

Targets first need to be mirrored to flutter/infra before they will be run.
This propagation takes about 30 minutes, and will only run as non-blocking in postsubmit.

The target will show runs in https://ci.chromium.org/p/flutter (under the repo). See
https://github.com/flutter/flutter/wiki/Adding-a-new-Test-Shard for up to date information
on the steps to promote your target to blocking.

For flutter/flutter, there's a GitHub bot that will
promote a test that has been passing for the past 50 runs.

### Test Ownership

**This only applies to flutter/flutter**

To prevent tests from rotting, all targets are required to have a clear owner. Add an
owner in [TESTOWNERS](https://github.com/flutter/flutter/blob/master/TESTOWNERS)

### Properties

Targets support specifying properties that can be passed throughout infrastructure. The
following are a list of keys that are reserved for special use.

**Properties is a Map<String, String> and any special values must be JSON encoded
(i.e. no trailing commas). Additionally, these strings must be compatible with YAML multiline strings**

**$flutter/osx_sdk**: xcode configs including sdk and runtime. **Note**: support on legacy `xcode`/`runtime`
properties and `xcode` dependency has been deprecated.

Example:
``` yaml
$flutter/osx_sdk : >-
  {
    "sdk_version": "14e222b",
    "runtime_versions":
      [
        "ios-16-4_14e222b",
        "ios-16-2_14c18"
      ]
  }
```

**add_recipes_cq**: String boolean whether to add this target to flutter/recipes CQ. This ensures
changes to flutter/recipes pass on this target before landing.

**dependencies**: JSON list of objects with "dependency" and optionally "version".
The list of supported deps is in [flutter_deps recipe_module](https://cs.opensource.google/flutter/recipes/+/master:recipe_modules/flutter_deps/api.py).
Dependencies generate a corresponding swarming cache that can be used in the
recipe code. The path of the cache will be the name of the dependency.

Versions can be located in [CIPD](https://chrome-infra-packages.appspot.com/)

Example
``` yaml
dependencies: >-
  [
    {"dependency": "android_sdk"},
    {"dependency": "chrome_and_driver", "version": "latest"},
    {"dependency": "clang"},
    {"dependency": "goldctl"}
  ]
```

**tags**: JSON list of strings. These are currently only used in flutter/flutter to help
with TESTOWNERSHIP and test flakiness.

Example
```yaml
tags: >
  ["devicelab","hostonly"]
```

**test_timeout_secs** String determining seconds before timeout for an individual test step.
Note that this is the timeout for a single test step rather than the entire build execution
timeout.

Example
``` yaml
test_timeout_secs: "2700"
```

**presubmit_max_attempts** The max attempts the target will be auto executed in presubmit. If it is
not specified, the default value is `1` and it means no auto rerun will happen. If explicitly defined,
it controls the max number of attempts. For example: `3` means it will be auto rescheduled two more times.

Example
``` yaml
presubmit_max_attempts: "3"
```

#### Engine V2 specific

##### archive

**cache_root** The base directory for the target cache where checkouts and other support files and 
source code will be added.

Example
```yaml
cache_name: "builder"
```

**cache_name** The target cache within the cache_root that will be archived/operated on.

Example
```yaml
cache_root: "cache"
```

**cache_paths** The paths within the cache specified by cache_name that will be archived/operated on.
These paths are assumed to have cache_root as a parent directory.

Example
```yaml
cache_paths: >-
  [
    "builder",
    "git"
  ]
```

**ignore_cache_paths** The paths within the cache that we do not want to include in the archive/current
operation. These paths are assumed to have cache_root as a parent directory. 

Example
```yaml
ignore_cache_paths: >-
  [
    "builder/src/flutter/prebuilts/SDKs"
  ]
```

### Updating targets

#### Properties
1. Find the cipd ref to upgrade to
    - If this is a Flutter managed package, look up its docs on uploading a new version
    - For example, JDK is at https://chrome-infra-packages.appspot.com/p/flutter_internal/java/openjdk/linux-amd64
2. In `ci.yaml`, find a target that would be impacted by this change
    - Override the `version` specified in dependencies
      ```yaml
      - name: Linux Host Engine
        recipe: engine
        properties:
          build_host: "true"
          dependencies: >-
          [
              {"dependency": "open_jdk", "version": "11"}
          ]
        timeout: 60
      ```
    - Send PR, wait for the checks to go green (**the change takes effect on both presubmit and postsubmit as cocoon scheduling**
    **fetches latest change and applies it to new builds immediately**)
3. If the check is red, add patches to get it green
4. Once the PR has landed, infrastructure may take 1 or 2 commits to apply the latest properties
   1. PRs/commits that have rebased on the changing PR do not need to wait
   2. PRs/commits that have not rebased on the changing PR need to wait
   3. Local LUCI runs need to wait
   4. Package cache needs to wait for roll out

**Note:** updates on other entries except `properties` will not take effect immediately. Ths PR needs
to be landed first to wait for changes propagated in infrastructure.

#### Update target platform

Target depends on the prefix platform in its `name` to decide which platform to run on. This should match
to an existing platform under `platform_properties`.

If one target needs to switch running platforms, e.g. from a devicelab bot to a host only bot:
1. Keep the old target entry
2. Add a new entry under the new platform with
  1. `bringup: true`
  2. necessary dependencies
  3. corresponding tags (tags will only be used for infra metrics analysis)
3. Land the change with the new entry
4. If the new target under the new platform passes in postsubmit
  1. Remove the old target entry and mark the new target as `bringup: false`

Example: say one wants to switch `Linux_android web_size__compile_test` to a vm.

Existing config:
```yaml
- name: Linux_android web_size__compile_test
  properties:
    tags: >
        ["devicelab", "android", "linux"]
```

Add a new config:
```yaml
- name: Linux web_size__compile_test
  bringup: true # new target
  properties:
    dependencies: >- # optional
      [
        {"dependency": "new-dependency", "version": "new-dependency-version"}
      ]
    tags: >
      ["devicelab", "hostonly", "linux"]
```

After validating the new target passes, lands the clean up change by removing the config of old target
`Linux_android web_size__compile_test` and removing the `bringup: true` for the new target.

Note: this change may affect benchmark metrics. Notify the metrics sherrif to monitor potential regression.

### External Tests

Cocoon supports tests that are not owned by Flutter infrastructure. By default, these should not block the tree but act as FYI to the gardeners.

1. Contact flutter-infra@ with your request (go/flutter-infra-office-hours)
2. Add your system to SchedulerSystem (https://github.com/flutter/cocoon/blob/master/app_dart/lib/src/model/proto/internal/scheduler.proto)
3. Add your service account to https://github.com/flutter/cocoon/blob/master/app_dart/lib/src/request_handling/swarming_authentication.dart
4. Add a custom frontend icon - https://github.com/flutter/cocoon/blob/master/dashboard/lib/widgets/task_icon.dart
5. Add a custom log link - https://github.com/flutter/cocoon/blob/master/dashboard/lib/logic/qualified_task.dart
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


## Scheduling Targets

For targets using the Cocoon scheduler, they can run on:
 * Presubmit (via GitHub checks)
 * Postsubmit (via [build dashboard](https://flutter-dashboard.appspot.com/#/build))

By default, all targets should use the Cocoon scheduler.

### Presubmit Features

1. GitHub checks enable targets to run immediately, and are available on the pull request page.
2. Changes to the ci.yaml will be applied during those presubmit runs.
3. New targets are required to be brought up with `bringup: true`

### Postsubmit Features

1. Targets are immediately triggered on GitHub webhooks for merged pull requests
2. Updates are made immediate via LUCI PubSub notifications
3. Prioritizes recently failed targets (to unblock the tree quicker)
4. Backfills targets at a low swarming priority when nothing is actively running
5. Batches targets that have a high queue time, and backfills in off peak hours
6. Flakiness monitoring

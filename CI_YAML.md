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
# dimensions: A list of testbed dimensions which the CI determines what testbed to assign a target to.
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

**Properties** is a Map<String, String> and any special values must be JSON encoded
(i.e. no trailing commas). Additionally, these strings must be compatible with YAML multiline strings

<table>
  <tr>
    <td>
      <b>Property Name</b>
    </td>
    <td>
      <b>Description</b>
    </td>
    <td>
      <b>Default Value</b>
    </td>
    <td>
      <b>Type</b>
    </td>
    <td>
      <b>Example</b>
    </td>
  </tr>
  <tr>
    <td>add_recipes_cq</td>
    <td>Whether to add this target to flutter/recipes CQ. This ensures
changes to flutter/recipes pass on this target before landing.
    </td>
    <td>"false"</td>
    <td>string bool</td>
    <td>

``` yaml
add_recipes_cq: "true"
```
</td>
  </tr>
  <tr>
    <td>cache_name</td>
    <td>The name identifier of the second layer Engine source cache. This is maintained by flutter/infra
    team via <a href="https://flutter.googlesource.com/recipes/+/refs/heads/main/recipes/engine_v2/cache.py">cache.py</a> recipe
    and is separate from LUCI side default caches.
    </td>
    <td>N/A</td>
    <td>string</td>
    <td>

``` yaml
cache_name: "builder"
```
</td>
  </tr>
  <tr>
    <td>cache_path</td>
    <td>The paths of Engine checkout source that will be auto saved to CAS for boosting source checkout when
caches no longer exist from the bots.
    </td>
    <td>N/A</td>
    <td>list</td>
    <td>

``` yaml
cache_paths: >-
  [
    "builder",
    "git"
  ]
```
</td>
  </tr>
  <tr>
    <td>clobber</td>
    <td>Whether to clean the Engine source code cache.
    </td>
    <td>"false"</td>
    <td>string bool</td>
    <td>

``` yaml
clobber: "true"
```
</td>
  </tr>
  <tr>
    <td>config_name</td>
    <td>The config name of the targets. It is used for <a href="https://flutter.googlesource.com/recipes/+/refs/heads/main/recipes/engine_v2">`Engine V2 recipes`</a>,
and is a one-on-one map to the config files located under <a href="https://github.com/flutter/engine/tree/main/ci/builders">`ci/builders`</a>. This is
not needed for targets using none `Engine V2 recipes`.
    </td>
    <td>N/A</td>
    <td>string</td>
    <td>

``` yaml
config_name: linux_benchmarks
```
</td>
  </tr>
  <tr>
  <td>contexts</td>
  <td>The list of contexts that will guide <a href="https://flutter.googlesource.com/recipes/+/refs/heads/main/recipe_modules/flutter_deps/api.py#665">recipes</a> to add to the <a href="https://docs.python.org/3/library/contextlib.html#contextlib.ExitStack">ExitStack</a>. This will initialize and prepare the virtual device used for tests. Other supported contexts include: `osx_sdk`, `depot_tools_on_path`, etc.
  </td>
  <td>N/A</td>
  <td>list</td>
  <td>

```yaml
contexts: >-
        [
          "android_virtual_device"
        ]
```
</td>
  </tr>
  <tr>
    <td>cores</td>
    <td>The machine cores a target will be running against. A higher number of cores may be needed for extensive targets.
    <br>
    Note: This property will be auto populated to CI builder dimensions, which CI uses to determine the
    testbed to run this target.
</td>
    <td>N/A</td>
    <td>string int</td>
    <td>

``` yaml
cores: "8"
```
</td>
  </tr>
  <tr>
    <td>dependencies</td>
    <td>JSON list of objects with "dependency" and optionally "version".
The list of supported deps is in <a href="https://cs.opensource.google/flutter/recipes/+/master:recipe_modules/flutter_deps/api.py">flutter_deps recipe_module</a>.
Dependencies generate a corresponding swarming cache that can be used in the
recipe code. The path of the cache will be the name of the dependency.
<br>
Versions can be located in <a href="https://chrome-infra-packages.appspot.com">CIPD</a>
    </td>
    <td>N/A</td>
    <td>list</td>
    <td>

``` yaml
dependencies: >-
  [
    {"dependency": "android_sdk"},
    {"dependency": "chrome_and_driver", "version": "latest"},
    {"dependency": "clang"},
    {"dependency": "goldctl"}
  ]
```
</td>
  </tr>
  <tr>
    <td>device_type</td>
    <td>The phone device type a target will be running against. For host only targets that do not need
    a phone, a value of `none` should be used.
    <br>
    Note: This property will be auto populated to CI builder dimensions, which CI uses to determine the
    testbed to run this target.
</td>
    <td>N/A</td>
    <td>string</td>
    <td>

``` yaml
device_type: "msm8952"
```
</td>
  </tr>
  <tr>
    <td>drone_dimensions</td>
    <td>A list of testbed dimensions which the CI determines what testbed to assign a subbuild drone of a target to. This
    property will be auto populated to CI dimensions of a subbuild triggered from the orchestrator target.
</td>
    <td>N/A</td>
    <td>string</td>
    <td>

``` yaml
drone_dimensions: >
  ["device_type=none", "os=Linux"]
```
</td>
  </tr>
  <tr>
    <td>$flutter/osx_sdk</td>
    <td>Xcode configs including sdk and runtime</td>
    <td>N/A</td>
    <td>map</td>
    <td>

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
</td>
  </tr>
  <tr>
    <td>gclient_variables</td>
    <td>The gclient variables populated to recipes when checking out sources via gclient sync.
    </td>
    <td>N/A</td>
    <td>map</td>
    <td>

``` yaml
gclient_variables: >-
  {
    "download_android_deps": "true"
  }
```
</td>
  </tr>
  <tr>
    <td>ignore_cache_paths</td>
    <td>The paths of Engine checkout source that will be skipped when saved to CAS. Please reference to `cache_path`.
    </td>
    <td>N/A</td>
    <td>list</td>
    <td>

``` yaml
ignore_cache_paths: >-
  [
    "buibuilder/src/flutter/prebuilts/SDKs",
    "builder/src/flutter/prebuilts/Library"lder"
  ]
```
</td>
  </tr>
  <tr>
    <td>no_goma</td>
    <td>Whether to use goma when building artifacts.
    </td>
    <td>"false"</td>
    <td>string bool</td>
    <td>

``` yaml
no_goma: "true"
```
</td>
  </tr>
  <tr>
    <td>os</td>
    <td>The machine os a target will be running against, such as `Linux`, `Mac-13`, etc.
    <br>
    Note: This property will be auto populated to CI builder dimensions, which CI uses to determine the
    testbed to run this target.
</td>
    <td>N/A</td>
    <td>string</td>
    <td>

``` yaml
os: Linux
```
</td>
  </tr>
  <tr>
  <td>presubmit_max_attempts</td>
  <td>The max attempts the target will be auto executed in presubmit. If it is
not specified, the default value is `1` and it means no auto rerun will happen. If explicitly defined,
it controls the max number of attempts. For example: `3` means it will be auto rescheduled two more times.
  </td>
  <td>"1"</td>
  <td>string int</td>
  <td>

``` yaml
presubmit_max_attempts: "3"
```
</td>
  </tr>
  <tr>
    <td>release_build</td>
    <td>Whether is required to run to release Engine. Will be triggered via
      <a href="https://flutter.googlesource.com/recipes/+/refs/heads/main/recipes/release/release_builder.py">release_builder.py</a>
    </td>
    <td>"false"</td>
    <td>string bool</td>
    <td>

``` yaml
release_build: "true"
```
</td>
  </tr>
  <tr>
    <td>shard</td>
    <td>The shard name of the sharding target, used in the <a href="https://github.com/flutter/flutter/blob/master/dev/bots/test.dart">test.dart</a> test runner.
    </td>
    <td>N/A</td>
    <td>string</td>
    <td>

``` yaml
shard: web_tests
```
</td>
  </tr>
  <tr>
    <td>subshards</td>
    <td>The sub shards of the sharding target, used in the <a href="https://github.com/flutter/flutter/blob/master/dev/bots/test.dart">test.dart</a> test runner.
If omitted with `shard` defined, it will run all unit tests in a single shard.
    </td>
    <td>N/A</td>
    <td>list</td>
    <td>

``` yaml
subshards: >-
  ["0", "1", "2", "3", "4", "5", "6", "7_last"]
```
</td>
  </tr>
  <tr>
    <td>tags</td>
    <td>JSON list of strings. These are currently only used in flutter/flutter to help
with TESTOWNERSHIP and test flakiness.
    </td>
    <td>N/A</td>
    <td>list</td>
    <td>

```yaml
tags: >
  ["devicelab","hostonly"]
```
</td>
  </tr>
  <tr>
    <td>test_timeout_secs</td>
    <td>String determining seconds before timeout for an individual test step.
Note that this is the timeout for a single test step rather than the entire build execution
timeout.
    </td>
    <td>"1800"</td>
    <td>string int</td>
    <td>

``` yaml
test_timeout_secs: "2700"
```
</td>
  </tr>
</table>

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

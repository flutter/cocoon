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

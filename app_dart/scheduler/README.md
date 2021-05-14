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
# Linux analyze will run on all presubmit and in postsubmit based on the LUCI builder `Linux analyze`.
 - name: Linux analyze
   builder: Linux analyze
# Linux licenses will run on postsubmit based on the LUCI builder `Linux analyze`,
# but it also passes the properties `analyze=true` to the builder. Since `bringup=true`,
# presubmit is not run, and postsubmit runs will not block the tree.
 - name: Linux licenses
   builder: Linux analyze
   bringup: true
   properties:
     - analyze: license
```
